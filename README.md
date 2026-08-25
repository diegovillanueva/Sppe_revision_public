# 🧊🛠️ CESM2.1.5 SPPE microphysics patch

🎯🧬 This package applies the study-specific microphysics controls in `patches/` to CAM tag `cam_cesm2_1_rel_60` and configures them with `namelists/user_nl_cam.sppe`.

🚀📦 Apply the complete patch set from a clean CAM checkout with:

```bash
git apply /path/to/Sppe_patch/patches/*.patch
```

## 🧩⚙️ Added controls

| 🧷🔤 Parameter | 🛠️🧭 What it fixes or controls |
|---|---|
| `hclas_du_imm` | 🟢🧊 Exposes dust immersion freezing as the retained and perturbable mixed-phase aerosol pathway. |
| `hclas_du_dep` | 🟤🛑 Removes the minor dust deposition-nucleation pathway when set to zero. |
| `hclas_du_cnt` | 🟤🛑 Removes the poorly constrained dust contact-freezing pathway when set to zero. |
| `hclas_bc_imm` | ⚫🛑 Removes the globally unimportant black-carbon immersion-freezing source when set to zero. |
| `hclas_bc_dep` | ⚫🛑 Removes the globally unimportant black-carbon deposition-nucleation source when set to zero. |
| `hclas_bc_cnt` | ⚫🛑 Removes the globally unimportant black-carbon contact-freezing source when set to zero. |
| `riming_factor` | ❄️🎛️ Exposes snow riming efficiency for perturbation before secondary-ice production is calculated. |
| `auto_liq_factor` | 🌧️🎛️ Exposes liquid autoconversion efficiency for perturbation. |
| `micro_mg_ice_berg_ice_factor` | 🧊🎛️ Separately scales Wegener--Bergeron--Findeisen deposition onto cloud ice. |
| `micro_mg_ice_berg_snow_factor` | ❄️🎛️ Separately scales Wegener--Bergeron--Findeisen deposition onto snow. |
| `factor_HM` | 🧪📉 Scales the Hallett--Mossop splinter source so the unsupported efficient source can be removed. |
| `onoff_sip` | 🧊🛑 Provides a redundant hard switch that prevents the Hallett--Mossop source from executing. |
| `onoff_contact_freezing` | 💧🛑 Disables CAM's legacy internal contact-freezing routine. |
| `rain_freeze` | 🌧️🛑 Removes INP-unaware, temperature-prescribed rain freezing. |
| `depr_point_frz` | 💧🔓 Bypasses artificial suppression of immersion freezing by the aerosol-solubility gate after activation. |
| `enable_nimax` | 🧊🔓 Removes the unphysical legacy maximum ice-number limiter. |
| `limfacdu` | 🟡📉 Replaces the broad ice-number limiter with a process-level cap on the fraction of dust activated as INPs per call. |
| `naai_het_also_in_mpc` | 🧊🚧 Prevents the cirrus ice-number target from leaking into mixed-phase clouds. |
| `detrainment_ramp_liq` | ☁️💧 Prevents INP-unaware mixed-phase detrained ice by retaining detrained condensate as liquid in the ramp interval. |

⏱️✅ The accompanying namelist also sets CAM's native `micro_mg_num_steps = 8` for a numerically converged microphysical substep length; this is not one of the 19 patch-added controls.

## 📄🎨 Technical appendix

📘🔍 The implementation excerpts, physical rationales, and references are documented in `latex/cesm215_sppe_namelist.tex`.

🧪📄 Build the standalone `latex/Sppe.pdf` with:

```bash
make -C latex
```
