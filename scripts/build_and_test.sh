#!/usr/bin/env bash
# 🧊🧪 Rebuild and run the pinned CESM2.1.5 CAM SPPE configuration.
set -euo pipefail

PACKAGE_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=../versions.env
source "${PACKAGE_ROOT}/versions.env"

WORK_ROOT="${WORK_ROOT:-${PACKAGE_ROOT}/work}"
CESM_ROOT="${CESM_ROOT:-${WORK_ROOT}/cesm215}"
CASES_ROOT="${CASES_ROOT:-${PACKAGE_ROOT}/cases}"
OUTPUT_ROOT="${OUTPUT_ROOT:-${PACKAGE_ROOT}/output}"
MACHINE="${MACHINE:-euler7}"
COMPILER="${COMPILER:-gnu}"
MPILIB="${MPILIB:-openmpi}"
PROJECT="${PROJECT:-control}"
QUEUE="${QUEUE:-normal.4h}"
RESOLUTION="${RESOLUTION:-f09_g17}"
COMPSET="${COMPSET:-F2000climo}"
NTASKS="${NTASKS:-512}"
STOP_OPTION="${STOP_OPTION:-ndays}"
STOP_N="${STOP_N:-1}"
EULER_CONFIG_BASE_URL="${EULER_CONFIG_BASE_URL:-https://git.iac.ethz.ch/cesm2/config/-/raw/main/cesm2.1.5}"

die() {
    printf '🔴❌ %s\n' "$*" >&2
    exit 1
}

require_file() {
    [[ -f "$1" ]] || die "Required file is missing: $1"
}

verify_revision() {
    local repository="$1" expected="$2" label="$3" actual
    actual="$(git -C "${repository}" rev-parse HEAD)"
    [[ "${actual}" == "${expected}" ]] ||
        die "${label} revision mismatch: expected ${expected}, found ${actual}"
}

checkout_source() {
    mkdir -p "${WORK_ROOT}"
    if [[ ! -d "${CESM_ROOT}/.git" ]]; then
        git clone --branch "${CESM_TAG}" "${CESM_REPOSITORY}" "${CESM_ROOT}"
    fi
    git -C "${CESM_ROOT}" checkout --detach "${CESM_COMMIT}"
    (
        cd "${CESM_ROOT}"
        ./manage_externals/checkout_externals
    )
    verify_revision "${CESM_ROOT}" "${CESM_COMMIT}" CESM
    verify_revision "${CESM_ROOT}/components/cam" "${CAM_COMMIT}" CAM
}

download_euler_config() {
    [[ "${MACHINE}" == "euler7" ]] || return 0
    local relative
    while read -r _ relative; do
        case "${relative}" in
            cime/config/cesm/config_inputdata.xml)
                remote=config_inputdata.xml
                ;;
            cime/config/cesm/machines/*)
                remote="machines/${relative##*/}"
                ;;
            cime/scripts/lib/CIME/XML/*)
                remote="XML/${relative##*/}"
                ;;
            *)
                die "Unsupported Euler configuration target: ${relative}"
                ;;
        esac
        mkdir -p "${CESM_ROOT}/$(dirname "${relative}")"
        curl --fail --location --silent --show-error \
            "${EULER_CONFIG_BASE_URL}/${remote}" \
            --output "${CESM_ROOT}/${relative}"
    done < "${PACKAGE_ROOT}/config/euler.sha256"
    (
        cd "${CESM_ROOT}"
        sha256sum -c "${PACKAGE_ROOT}/config/euler.sha256"
    )
}

apply_patches() {
    verify_revision "${CESM_ROOT}" "${CESM_COMMIT}" CESM
    verify_revision "${CESM_ROOT}/components/cam" "${CAM_COMMIT}" CAM
    if git -C "${CESM_ROOT}/components/cam" apply --reverse --check \
        "${PACKAGE_ROOT}"/patches/*.patch >/dev/null 2>&1; then
        printf '🟢✅ CAM patches are already applied\n'
        return 0
    fi
    git -C "${CESM_ROOT}/components/cam" apply --check \
        "${PACKAGE_ROOT}"/patches/*.patch
    git -C "${CESM_ROOT}/components/cam" apply \
        "${PACKAGE_ROOT}"/patches/*.patch
}

write_case_namelist() {
    local case_root="$1" riming_factor="$2"
    require_file "${PACKAGE_ROOT}/namelists/user_nl_cam.sppe"
    [[ -n "${NUDGE_PATH:-}" ]] || die "NUDGE_PATH must identify the ERA5 nudging directory"
    awk -v nudging="${NUDGE_PATH%/}/" -v riming="${riming_factor}" '
        /^[[:space:]]*Nudge_Path[[:space:]]*=/ {
            printf "Nudge_Path = '\''%s'\''\n", nudging
            nudge_seen++; next
        }
        /^[[:space:]]*riming_factor[[:space:]]*=/ {
            printf "riming_factor = %s\n", riming
            riming_seen++; next
        }
        { print }
        END {
            if (nudge_seen != 1 || riming_seen != 1) exit 2
        }
    ' "${PACKAGE_ROOT}/namelists/user_nl_cam.sppe" > "${case_root}/user_nl_cam"
}

create_case() {
    local case_label="$1" riming_factor="$2"
    [[ -n "${DIN_LOC_ROOT:-}" ]] || die "DIN_LOC_ROOT must identify CESM input data"
    local case_name="cesm215.${COMPSET}.Sppe_patch_${case_label}_ndg"
    local case_root="${CASES_ROOT}/${case_name}"
    [[ ! -e "${case_root}" ]] || die "Case already exists: ${case_root}"
    mkdir -p "${CASES_ROOT}" "${OUTPUT_ROOT}"
    "${CESM_ROOT}/cime/scripts/create_newcase" \
        --case "${case_root}" \
        --compset "${COMPSET}" \
        --res "${RESOLUTION}" \
        --machine "${MACHINE}" \
        --compiler "${COMPILER}" \
        --mpilib "${MPILIB}" \
        --project "${PROJECT}" \
        --queue "${QUEUE}" \
        --output-root "${OUTPUT_ROOT}" \
        --input-dir "${DIN_LOC_ROOT}" \
        --run-unsupported
    (
        cd "${case_root}"
        ./xmlchange "STOP_OPTION=${STOP_OPTION},STOP_N=${STOP_N}"
        ./xmlchange "REST_OPTION=${STOP_OPTION},REST_N=${STOP_N}"
        ./xmlchange CONTINUE_RUN=FALSE,RESUBMIT=0,DOUT_S=FALSE
        ./xmlchange RUN_STARTDATE=2000-01-01
        ./xmlchange "NTASKS_CPL=${NTASKS},NTASKS_ATM=${NTASKS},NTASKS_OCN=${NTASKS},NTASKS_ICE=${NTASKS},NTASKS_LND=${NTASKS},NTASKS_WAV=16,NTASKS_GLC=${NTASKS},NTASKS_ROF=${NTASKS},NTASKS_ESP=1"
        ./xmlchange --append CAM_CONFIG_OPTS=-cosp
        ./xmlchange GMAKE_J=20
        write_case_namelist "${case_root}" "${riming_factor}"
        ./case.setup
        ./preview_namelists
        ./check_input_data
    )
    printf '🟢✅ Created case %s\n' "${case_root}"
}

case_root_for() {
    printf '%s/cesm215.%s.Sppe_patch_%s_ndg' "${CASES_ROOT}" "${COMPSET}" "$1"
}

build_case() {
    local case_root
    case_root="$(case_root_for "$1")"
    [[ -x "${case_root}/case.build" ]] || die "Case is not configured: ${case_root}"
    (cd "${case_root}" && ./case.build)
}

submit_case() {
    local case_root
    case_root="$(case_root_for "$1")"
    [[ -x "${case_root}/case.submit" ]] || die "Case is not configured: ${case_root}"
    (cd "${case_root}" && ./case.submit)
}

usage() {
    printf '%s\n' \
        '🧊🧪 Usage:' \
        '  build_and_test.sh checkout' \
        '  build_and_test.sh patch' \
        '  build_and_test.sh create CASE_LABEL RIMING_FACTOR' \
        '  build_and_test.sh build CASE_LABEL' \
        '  build_and_test.sh submit CASE_LABEL' \
        '  build_and_test.sh all CASE_LABEL RIMING_FACTOR'
}

main() {
    local command="${1:-help}"
    case "${command}" in
        checkout)
            checkout_source
            download_euler_config
            ;;
        patch)
            apply_patches
            ;;
        create)
            [[ $# -eq 3 ]] || die "create requires CASE_LABEL and RIMING_FACTOR"
            create_case "$2" "$3"
            ;;
        build)
            [[ $# -eq 2 ]] || die "build requires CASE_LABEL"
            build_case "$2"
            ;;
        submit)
            [[ $# -eq 2 ]] || die "submit requires CASE_LABEL"
            submit_case "$2"
            ;;
        all)
            [[ $# -eq 3 ]] || die "all requires CASE_LABEL and RIMING_FACTOR"
            checkout_source
            download_euler_config
            apply_patches
            create_case "$2" "$3"
            build_case "$2"
            submit_case "$2"
            ;;
        help|-h|--help)
            usage
            ;;
        *)
            usage >&2
            die "Unknown command: ${command}"
            ;;
    esac
}

main "$@"
