# 🧊🧪 CESM2.1.5 SPPE patch package

🎯🔬 This directory is the minimal, independently publishable source package for rebuilding and running the patched CESM2.1.5 CAM SPPE configuration.

📦🌳 The directory remains an ordinary tracked subtree of PPF and can later be published independently with `git subtree split --prefix=data_code/cesm215/Sppe_patch`.

## 🧩📂 Contents

- 🧬🔒 `versions.env` pins the upstream CESM and CAM tags and commits.
- 🛠️🧩 `patches/` contains the ten CAM patches that must be applied together.
- 📋🎛️ `namelists/user_nl_cam.sppe` is the tested canonical SPPE and ERA5-nudging template.
- 🚀⚙️ `scripts/build_and_test.sh` checks out, patches, configures, builds, and optionally submits a smoke test.
- 🔬⚖️ `scripts/compare_cam_outputs.py` performs exact scientific-variable comparisons between paired CAM history files.
- 🏔️🔐 `config/euler.sha256` verifies the six external Euler CIME configuration files downloaded by the driver.
- 🌍📦 `inputs/README.md` defines the required external CESM and ERA5 data contract.
- 📄🎨 `latex/` contains the standalone Appendix G source, its local icon definitions, and the wrapper that builds `Sppe.pdf`.
- 🧾🔐 `SHA256SUMS` verifies every portable package input.

## 📄🎨 Standalone Appendix G

🧊📘 Build the standalone explanation of the SPPE microphysics controls with:

```bash
make -C latex
```

📄✅ The build writes `latex/Sppe.pdf` and requires only a LaTeX installation providing `geometry`, `array`, `booktabs`, `longtable`, `url`, `hyperref`, `xcolor`, and `fontawesome5`.

🔗🛡️ The manuscript-facing path `tex_sections/cesm215_sppe_namelist.tex` remains a compatibility symlink to the authoritative source in this directory.

## 🚀🟢 Quick start on Euler

🟣📌 Set the two external-data roots, then run the complete reference-case workflow:

```bash
export DIN_LOC_ROOT=/cluster/work/climate/cesm/inputdata
export NUDGE_PATH=/nfs/n2o/wolke_scratch/GLANCE/cesm_input/CESM_nudging_files
./scripts/build_and_test.sh all reference 1
```

🟠🧪 Build a perturbation case with `riming_factor = 1e-2` by running:

```bash
./scripts/build_and_test.sh all rim_m2 1e-2
```

🔵📋 Run individual stages with `checkout`, `patch`, `create`, `build`, or `submit`; `./scripts/build_and_test.sh help` prints their interfaces.

## 🧬✅ Source contract

🟢🔒 The driver requires CESM commit `7a6c5b0d4e045085633dd9553cdd6aa8a8ea728d` and CAM commit `a03b84b7c4e34f965b115686f22a043b85739e56` before applying any patch.

🟢🧩 The patches expose exactly 19 runtime controls and have passed clean application, compilation, patched-runtime, and pristine-equivalence tests documented in the parent PPF repository.

## 🌳📤 Independent publication

🟣🔀 From the PPF repository root, create an independent branch with:

```bash
git subtree split --prefix=data_code/cesm215/Sppe_patch -b sppe-patch-release
```

🔵🚀 Push that branch to the independent repository without embedding a nested `.git` directory inside PPF.
