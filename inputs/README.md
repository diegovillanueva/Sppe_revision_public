# 🌍📦 External input data

🔴📌 CESM input data are intentionally excluded from Git and must be supplied through `DIN_LOC_ROOT`.

🌬️📌 ERA5 nudging files are intentionally excluded and must be supplied through `NUDGE_PATH` with filenames matching `ERA5_x_fv1x1_L32_rgC2_WO.%y-%m-%d-%s.nc`.

📅🧭 The smoke-test namelist starts on `2000-01-01`, reads four nudging analyses per day, and therefore requires coverage beginning on that date.

🔐🧾 A publisher should accompany a release with a SHA-256 manifest for the exact external files used, generated outside Git with:

```bash
find "$DIN_LOC_ROOT" "$NUDGE_PATH" -type f -print0 | sort -z | xargs -0 sha256sum > inputdata.sha256
```

🟠⚠️ The full CESM input-data tree is large, so the release manifest may be limited to files reported by the generated CIME `*.input_data_list` files plus the ERA5 files actually read by the requested run interval.
