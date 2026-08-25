#!/usr/bin/env python3
"""🔵⚖️ Compare paired CAM history files exactly, excluding global provenance metadata."""

from __future__ import annotations

import argparse
from pathlib import Path
import sys

import netCDF4
import numpy as np

PROVENANCE_VARIABLES = {"date_written", "time_written"}


def history_key(path: Path) -> str:
    """🔵🗂️ Return the CAM stream-and-timestamp suffix used to pair case files."""
    marker = ".cam."
    if marker not in path.name:
        raise ValueError(f"🟠⚠️ Not a CAM history filename: {path.name}")
    return path.name.split(marker, 1)[1]


def inventory(directory: Path) -> dict[str, Path]:
    """🟣📋 Index all CAM history files in a run directory by comparable suffix."""
    files = sorted(directory.glob("*.cam.h*.nc"))
    return {history_key(path): path for path in files}


def compare_variable(name: str, left, right) -> list[str]:
    """🟢🔬 Return exact metadata-and-value differences for one NetCDF variable."""
    differences: list[str] = []
    if left.dimensions != right.dimensions:
        differences.append(
            f"🟠📐 {name}: dimensions differ: {left.dimensions} != {right.dimensions}"
        )
    if left.dtype != right.dtype:
        differences.append(f"🟠🔢 {name}: dtype differs: {left.dtype} != {right.dtype}")
    left_attrs = {key: left.getncattr(key) for key in left.ncattrs()}
    right_attrs = {key: right.getncattr(key) for key in right.ncattrs()}
    if left_attrs != right_attrs:
        differences.append(f"🟠🏷️ {name}: variable attributes differ")

    left_values = left[:]
    right_values = right[:]
    left_mask = np.ma.getmaskarray(left_values)
    right_mask = np.ma.getmaskarray(right_values)
    if not np.array_equal(left_mask, right_mask):
        differences.append(f"🔴🎭 {name}: missing-value masks differ")
        return differences

    left_data = np.ma.getdata(left_values)
    right_data = np.ma.getdata(right_values)
    if left_data.shape != right_data.shape:
        differences.append(
            f"🔴📐 {name}: shapes differ: {left_data.shape} != {right_data.shape}"
        )
    else:
        try:
            values_equal = np.array_equal(left_data, right_data, equal_nan=True)
        except TypeError:
            values_equal = np.array_equal(left_data, right_data)
    if left_data.shape == right_data.shape and not values_equal:
        valid = ~left_mask
        if np.issubdtype(left_data.dtype, np.number) and np.any(valid):
            delta = np.abs(left_data[valid] - right_data[valid])
            differences.append(
                f"🔴📉 {name}: values differ; max_abs_diff={np.max(delta)!r}"
            )
        else:
            differences.append(f"🔴📉 {name}: values differ")
    return differences


def compare_file(left_path: Path, right_path: Path) -> list[str]:
    """🧪⚖️ Compare dimensions and every variable in a paired history file."""
    differences: list[str] = []
    with netCDF4.Dataset(left_path) as left, netCDF4.Dataset(right_path) as right:
        left_dims = {name: (len(dim), dim.isunlimited()) for name, dim in left.dimensions.items()}
        right_dims = {name: (len(dim), dim.isunlimited()) for name, dim in right.dimensions.items()}
        if left_dims != right_dims:
            differences.append("🔴📐 File dimensions differ")

        left_names = set(left.variables) - PROVENANCE_VARIABLES
        right_names = set(right.variables) - PROVENANCE_VARIABLES
        if left_names != right_names:
            differences.append(
                f"🔴📋 Variable sets differ; left_only={sorted(left_names - right_names)}, "
                f"right_only={sorted(right_names - left_names)}"
            )
        for name in sorted(left_names & right_names):
            differences.extend(compare_variable(name, left.variables[name], right.variables[name]))
    return differences


def main() -> int:
    """🟢🚦 Compare two run directories and return failure for any scientific difference."""
    parser = argparse.ArgumentParser(
        description="🔵⚖️ Compare CAM history scientific dimensions, variables, masks, metadata, and values exactly."
    )
    parser.add_argument("patched", type=Path)
    parser.add_argument("unpatched", type=Path)
    args = parser.parse_args()

    patched = inventory(args.patched)
    unpatched = inventory(args.unpatched)
    if set(patched) != set(unpatched):
        print(
            f"🔴📂 History-file sets differ; patched_only={sorted(set(patched) - set(unpatched))}, "
            f"unpatched_only={sorted(set(unpatched) - set(patched))}"
        )
        return 1

    all_differences: list[str] = []
    for key in sorted(patched):
        differences = compare_file(patched[key], unpatched[key])
        if differences:
            all_differences.append(f"🔴📄 {key} differs")
            all_differences.extend(f"  {difference}" for difference in differences)
        else:
            print(f"🟢✅ {key}: exact variable-level match")

    if all_differences:
        print("\n".join(all_differences))
        return 1
    print(f"🟢🏁 All {len(patched)} paired CAM history files match exactly")
    return 0


if __name__ == "__main__":
    sys.exit(main())
