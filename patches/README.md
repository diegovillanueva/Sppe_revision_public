# 🧊🛠️ Curated CAM source patches

🎯🧬 These patches apply directly to CAM tag `cam_cesm2_1_rel_60` and reproduce the custom source behavior configured by `../namelists/user_nl_cam.sppe`.

🚀📦 Apply all patches from the root of a clean CAM checkout:

```bash
git apply /path/to/Sppe_patch/patches/*.patch
```

🧩✅ The files are independent unified diffs and may be applied together.

📚🟣 The set contains:

- 🟢⚙️ `micro_dv_nml.F90.patch` adds the namelist reader, MPI broadcasts, baseline-equivalent defaults, and logging.
- 🟣📋 `namelist_definition.xml.patch` adds exactly the 19 study-exposed namelist definitions.
- 🔵🔌 `microp_aero.F90.patch` adds the initialization hook for the new namelist reader.
- 🧊🌨️ `hetfrz_classnuc*.patch` adds freezing-point-depression selection, the dust INP cap, and dust/black-carbon factors.
- ☁️⚙️ `micro_mg1_0.F90.patch` and `micro_mg2_0.F90.patch` add the ice-number-cap switch, leak fix, PPE process factors, and detrainment behavior.
- 🌧️🧪 `micro_mg_utils.F90.patch` adds contact-freezing, SIP/Hallett-Mossop, and rain-freezing controls.
- 💧🔀 `clubb_intr.F90.patch` and `macrop_driver.F90.patch` add the liquid-detrainment switch.

## 🟣📋 Included namelist inputs

`hclas_du_imm`, `hclas_du_dep`, `hclas_du_cnt`, `hclas_bc_imm`,
`hclas_bc_dep`, `hclas_bc_cnt`, `riming_factor`, `auto_liq_factor`,
`micro_mg_ice_berg_ice_factor`, `micro_mg_ice_berg_snow_factor`, `factor_HM`,
`onoff_sip`, `onoff_contact_freezing`, `rain_freeze`, `depr_point_frz`,
`enable_nimax`, `limfacdu`, `naai_het_also_in_mpc`, and
`detrainment_ramp_liq`.

🧹🛡️ No unrelated development-branch controls or helper variables are included in the curated module or consumer patches.

🧊✅ In particular, the patches use the CESM2.1.5 baseline temperature and supersaturation expressions rather than requiring `tk_apparent`, `supersatice_ramp`, or their associated ramp controls.

🔍✅ The `micro_dv_nml` module exposes exactly these 19 inputs and keeps `micro_dv_readnl` public for CAM initialization.

🔄🛠️ Within PPF, the patches can be regenerated with `../tools/generate_patches.py`; the generator reads tracked Git blobs at the pinned revisions, so untracked files in the CESM source tree are ignored.

🧪✅ Audit the regenerated bundle with `git apply --check` against `cam_cesm2_1_rel_60`, apply all patches to an isolated copy, and compare the resulting changed-file set with this directory.
