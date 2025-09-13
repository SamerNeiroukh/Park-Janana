#!/usr/bin/env python3
import sys
import argparse
from collections import defaultdict
from pathlib import Path

def parse_lcov(path):
    """
    Parse an lcov.info file and return a dict:
      { "<source_file_path>": {"LH": int, "LF": int} }
    """
    file_cov = defaultdict(lambda: {"LH": 0, "LF": 0})
    current_file = None

    with open(path, "r", encoding="utf-8") as f:
        for raw in f:
            line = raw.strip()
            if not line:
                continue

            if line.startswith("SF:"):
                current_file = line[3:]
                _ = file_cov[current_file]  # ensure entry exists

            elif line.startswith("LH:"):
                if current_file is not None:
                    try:
                        file_cov[current_file]["LH"] += int(line[3:])
                    except ValueError:
                        pass

            elif line.startswith("LF:"):
                if current_file is not None:
                    try:
                        file_cov[current_file]["LF"] += int(line[3:])
                    except ValueError:
                        pass

            elif line == "end_of_record":
                current_file = None

    return file_cov

def compute_percent(lh, lf):
    if lf <= 0:
        return 0.0
    return (lh / lf) * 100.0

def guess_lcov_path(explicit: str | None) -> Path | None:
    if explicit:
        p = Path(explicit)
        return p if p.is_file() else None

    here = Path.cwd()
    script_dir = Path(__file__).parent

    candidates = [
        here / "lcov.info",
        here / "coverage" / "lcov.info",
        script_dir / "lcov.info",
        script_dir / "coverage" / "lcov.info",
        here.parent / "coverage" / "lcov.info",
    ]
    for p in candidates:
        if p.is_file():
            return p
    return None

def main():
    ap = argparse.ArgumentParser(
        description="Summarize Flutter LCOV coverage per file and overall."
    )
    # Path is optional now
    ap.add_argument("lcov", nargs="?", help="Path to lcov.info (defaults to auto-detect)")
    ap.add_argument("--sort", choices=["file", "asc", "desc"], default="desc",
                    help="Sort per-file rows by coverage: file name, ascending, or descending (default)")
    ap.add_argument("--include-zero", action="store_true",
                    help="Include files with 0 total lines (LF==0) if present")
    args = ap.parse_args()

    lcov_path = guess_lcov_path(args.lcov)
    if not lcov_path:
        print("Could not find lcov.info automatically. "
              "Try running from the folder containing lcov.info or pass a path.")
        sys.exit(1)

    data = parse_lcov(lcov_path)

    rows = []
    total_lh = 0
    total_lf = 0

    for sf, vals in data.items():
        lh = vals["LH"]
        lf = vals["LF"]
        if lf == 0 and not args.include_zero:
            continue
        pct = compute_percent(lh, lf) if lf > 0 else 0.0
        rows.append((sf, lh, lf, pct))
        total_lh += lh
        total_lf += lf

    # sorting
    if args.sort == "file":
        rows.sort(key=lambda r: r[0].lower())
    elif args.sort == "asc":
        rows.sort(key=lambda r: (r[3], r[0].lower()))
    else:  # desc
        rows.sort(key=lambda r: (-r[3], r[0].lower()))

    # print per-file
    print("Per-file coverage:")
    print(f"{'Coverage %':>10}  {'LH':>6}/{ 'LF':<6}  File")
    for sf, lh, lf, pct in rows:
        print(f"{pct:9.2f}%  {lh:6}/{lf:<6}  {sf}")

    # overall
    overall_pct = compute_percent(total_lh, total_lf) if total_lf > 0 else 0.0
    print("\nOverall:")
    print(f"  Lines hit (LH): {total_lh}")
    print(f"  Lines found (LF): {total_lf}")
    print(f"  Total coverage: {overall_pct:.2f}%")

if __name__ == "__main__":
    main()
