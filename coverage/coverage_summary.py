#!/usr/bin/env python3
import sys
import os
import argparse
import subprocess
import shutil
from collections import defaultdict
from pathlib import Path
from typing import Optional, Dict

def resolve_flutter(cmd_opt: Optional[str]) -> Optional[str]:
    """
    Resolve a usable flutter executable path.
    Order:
      1) --flutter argument (file or directory)
      2) FLUTTER_BIN (file or directory)
      3) FLUTTER_HOME (uses <home>/bin/flutter[.bat])
      4) PATH (shutil.which)
      5) Common install locations (Windows/mac/Linux/FVM)
    """
    candidates = []

    def add_execs(p: Path):
        # Add both unix and windows variants
        candidates.extend([p / "flutter", p / "flutter.bat"])

    # 1) --flutter
    if cmd_opt:
        p = Path(cmd_opt)
        if p.is_dir():
            add_execs(p)
        else:
            candidates.append(p)

    # 2) FLUTTER_BIN
    fb = os.environ.get("FLUTTER_BIN")
    if fb:
        p = Path(fb)
        if p.is_dir():
            add_execs(p)
        else:
            candidates.append(p)

    # 3) FLUTTER_HOME
    fh = os.environ.get("FLUTTER_HOME")
    if fh:
        add_execs(Path(fh) / "bin")

    # 4) PATH
    which = shutil.which("flutter")
    if which:
        return which

    # 5) Common locations
    # Windows typical
    candidates.append(Path(r"C:\src\flutter\bin\flutter.bat"))
    user = os.environ.get("USERPROFILE")
    if user:
        candidates.append(Path(user) / "fvm" / "default" / "bin" / "flutter.bat")
    # mac/Linux typical
    home = Path.home()
    candidates.extend([
        home / "fvm" / "default" / "bin" / "flutter",
        home / ".asdf" / "shims" / "flutter",
        home / "flutter" / "bin" / "flutter",
        Path("/usr/local/bin/flutter"),
        Path("/opt/homebrew/bin/flutter"),  # Apple Silicon Homebrew
    ])

    for c in candidates:
        if c and Path(c).exists():
            return str(c)

    return None

def run_flutter_tests(project_dir: Path, flutter_cmd: str) -> None:
    print(f"Running Flutter tests with coverage in: {project_dir}")
    print(f"Using Flutter at: {flutter_cmd}")
    try:
        subprocess.run(
            [flutter_cmd, "test", "--coverage"],
            cwd=project_dir,
            check=True,
        )
    except FileNotFoundError:
        print("Error: Flutter executable not found at the resolved path.")
        sys.exit(1)
    except subprocess.CalledProcessError as e:
        print(f"Flutter tests failed with exit code {e.returncode}.")
        sys.exit(e.returncode)

def parse_lcov(path: Path) -> Dict[str, Dict[str, int]]:
    """
    Parse an lcov.info file and return a dict:
      { "<source_file_path>": {"LH": int, "LF": int} }
    """
    from collections import defaultdict
    file_cov = defaultdict(lambda: {"LH": 0, "LF": 0})
    current_file = None

    with path.open("r", encoding="utf-8") as f:
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

def compute_percent(lh: int, lf: int) -> float:
    if lf <= 0:
        return 0.0
    return (lh / lf) * 100.0

def main():
    ap = argparse.ArgumentParser(
        description="Run `flutter test --coverage` from project root and summarize LCOV coverage."
    )
    ap.add_argument("--sort", choices=["file", "asc", "desc"], default="desc",
                    help="Sort per-file rows by coverage: file name, ascending, or descending (default)")
    ap.add_argument("--include-zero", action="store_true",
                    help="Include files with 0 total lines (LF==0) if present")
    ap.add_argument("--no-run", action="store_true",
                    help="Skip running tests; just parse existing coverage/lcov.info")
    ap.add_argument("--flutter", help="Path to flutter executable OR its bin directory (e.g. C:\\src\\flutter\\bin\\flutter.bat)")
    args = ap.parse_args()

    # Script is expected at <project_root>/coverage/coverage_summary.py
    script_dir = Path(__file__).resolve().parent          # .../coverage
    project_dir = script_dir.parent                       # project root
    lcov_path = script_dir / "lcov.info"                  # .../coverage/lcov.info

    # Resolve flutter
    flutter_cmd = resolve_flutter(args.flutter)

    # 1) Run tests with coverage (unless skipped)
    if not args.no_run:
        if not flutter_cmd:
            print("Error: 'flutter' command not found.\n"
                  "Fix one of the following and re-run, or use --no-run to skip test execution:\n"
                  "  - Pass --flutter \"C:\\\\src\\\\flutter\\\\bin\\\\flutter.bat\" (Windows) or path to flutter\n"
                  "  - Set FLUTTER_BIN or FLUTTER_HOME env vars\n"
                  "  - Add Flutter to your PATH")
            sys.exit(1)
        run_flutter_tests(project_dir, flutter_cmd)

    # 2) Verify LCOV file
    if not lcov_path.is_file():
        print(f"Could not find lcov.info at: {lcov_path}")
        print("Tip: run without --no-run (and ensure Flutter is available) to generate it.")
        sys.exit(1)

    # 3) Parse and summarize
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
    print("\nPer-file coverage:")
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
