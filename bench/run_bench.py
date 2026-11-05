"""Run the on-device benchmark (NFR1, NFR2) on a connected phone.

Builds the bench entrypoint (mobile/lib/bench/bench_main.dart) in release mode,
installs it, starts it --runs times (each start is a fresh process, so every
load is a cold load), and appends one CSV row per model per run to
bench/results.csv. Device facts come from adb; the measurements come from the
phone's own output. Nothing is estimated.

    python bench/run_bench.py --note "charging, screen on"
    python bench/run_bench.py --serial R58M123ABC --runs 5

The bench build replaces the app on the phone (same package). Use the test
phones only; reinstall the app afterwards with `flutter install --release`.
Standard library only.
"""

from __future__ import annotations

import argparse
import csv
import json
import re
import subprocess
import sys
import time
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
MOBILE = ROOT / "mobile"
RESULTS = ROOT / "bench" / "results.csv"
APK = MOBILE / "build" / "app" / "outputs" / "flutter-apk" / "app-release.apk"
PACKAGE = "zm.ac.zcas.sfm_lcp"
ACTIVITY = f"{PACKAGE}/.MainActivity"
TAG = "SFMBENCH"
DONE = "SFMBENCH_DONE"

# The CSV contract. Columns are only ever added at the end.
COLUMNS = [
    "timestamp_utc",
    "git_sha",
    "git_dirty",
    "run",
    "device_manufacturer",
    "device_model",
    "soc",
    "android_api",
    "ram_total_mb",
    "build_mode",
    "model",
    "model_version",
    "model_bytes",
    "load_ms",
    "rss_before_load_mb",
    "rss_after_load_mb",
    "first_call_us",
    "warmup",
    "n",
    "p50_us",
    "p95_us",
    "max_us",
    "mean_us",
    "inputs",
    "app_pss_mb",
    "note",
]


# ---------------------------------------------------------------- parsing


def parse_bench_lines(log: str) -> tuple[list[dict], bool, list[str]]:
    """The phone's results, whether it finished, and any error lines."""
    results, errors, done = [], [], False
    for line in log.splitlines():
        if DONE in line:
            done = True
            continue
        at = line.find(f"{TAG} ")
        if at < 0:
            continue
        payload = line[at + len(TAG) + 1 :].strip()
        if payload.startswith("{"):
            results.append(json.loads(payload))
        else:
            errors.append(payload)
    return results, done, errors


def parse_pss_kb(meminfo: str) -> int | None:
    """TOTAL PSS from `dumpsys meminfo <package>`, in kB."""
    m = re.search(r"TOTAL PSS:\s*(\d+)", meminfo)  # Android 10+
    if m is None:
        m = re.search(r"^\s*TOTAL\s+(\d+)", meminfo, re.MULTILINE)  # older
    return int(m.group(1)) if m else None


def parse_mem_total_kb(proc_meminfo: str) -> int | None:
    m = re.search(r"MemTotal:\s*(\d+)\s*kB", proc_meminfo)
    return int(m.group(1)) if m else None


def mb(n_bytes: float) -> float:
    return round(n_bytes / (1024 * 1024), 2)


def to_row(result: dict, device: dict, run: int, common: dict) -> dict:
    """One CSV row from one model's result line plus the run's context."""
    if result["build_mode"] != "release":
        raise ValueError(f"not a release build: {result['build_mode']}")
    row = {
        **common,
        **device,
        "run": run,
        "build_mode": result["build_mode"],
        "model": result["model"],
        "model_version": result["model_version"],
        "model_bytes": result["model_bytes"],
        "load_ms": result["load_ms"],
        "rss_before_load_mb": mb(result["rss_before_load_bytes"]),
        "rss_after_load_mb": mb(result["rss_after_load_bytes"]),
        "first_call_us": result["first_call_us"],
        "warmup": result["warmup"],
        "n": result["n"],
        "p50_us": result["p50_us"],
        "p95_us": result["p95_us"],
        "max_us": result["max_us"],
        "mean_us": result["mean_us"],
        "inputs": result["inputs"],
    }
    return {c: row.get(c, "") for c in COLUMNS}


def append_rows(path: Path, rows: list[dict]) -> None:
    new = not path.exists()
    if not new:
        with path.open(newline="", encoding="utf-8") as f:
            header = next(csv.reader(f), [])
        if header != COLUMNS[: len(header)]:
            raise SystemExit(f"{path} has a different header; not appending.")
    with path.open("a", newline="", encoding="utf-8") as f:
        w = csv.DictWriter(f, fieldnames=COLUMNS, lineterminator="\n")
        if new:
            w.writeheader()
        w.writerows(rows)


# ---------------------------------------------------------------- the phone


def sh(cmd: list[str], cwd: Path | None = None) -> str:
    return subprocess.run(
        cmd, cwd=cwd, check=True, capture_output=True, text=True, encoding="utf-8",
        errors="replace", shell=sys.platform == "win32" and cmd[0] == "flutter",
    ).stdout


def adb(serial: str | None, *args: str) -> str:
    return sh(["adb", *(["-s", serial] if serial else []), *args])


def device_facts(serial: str | None) -> dict:
    def prop(name: str) -> str:
        return adb(serial, "shell", "getprop", name).strip()

    total_kb = parse_mem_total_kb(adb(serial, "shell", "cat", "/proc/meminfo"))
    return {
        "device_manufacturer": prop("ro.product.manufacturer"),
        "device_model": prop("ro.product.model"),
        "soc": prop("ro.soc.model") or prop("ro.board.platform"),
        "android_api": prop("ro.build.version.sdk"),
        "ram_total_mb": round(total_kb / 1024) if total_kb else "",
    }


def git_facts() -> dict:
    sha = sh(["git", "rev-parse", "--short", "HEAD"], cwd=ROOT).strip()
    dirty = bool(sh(["git", "status", "--porcelain", "--", "mobile"], cwd=ROOT).strip())
    return {"git_sha": sha, "git_dirty": int(dirty)}


def one_run(serial: str | None, timeout_s: int) -> tuple[list[dict], int | None]:
    adb(serial, "shell", "am", "force-stop", PACKAGE)
    adb(serial, "logcat", "-c")
    adb(serial, "shell", "am", "start", "-W", "-n", ACTIVITY)
    deadline = time.monotonic() + timeout_s
    while True:
        log = adb(serial, "logcat", "-d", "-s", "flutter")
        results, done, errors = parse_bench_lines(log)
        if done:
            break
        if time.monotonic() > deadline:
            raise SystemExit(f"no {DONE} within {timeout_s}s; is the phone unlocked?")
        time.sleep(2)
    if errors:
        raise SystemExit("the benchmark failed on the phone:\n" + "\n".join(errors))
    pss = parse_pss_kb(adb(serial, "shell", "dumpsys", "meminfo", PACKAGE))
    adb(serial, "shell", "am", "force-stop", PACKAGE)
    return results, pss


def main() -> None:
    p = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    p.add_argument("--serial", help="adb serial, when more than one phone is attached")
    p.add_argument("--runs", type=int, default=3, help="app starts (default 3)")
    p.add_argument("--iterations", type=int, default=1000)
    p.add_argument("--warmup", type=int, default=100)
    p.add_argument("--timeout", type=int, default=300, help="seconds per run")
    p.add_argument("--note", default="", help="conditions, e.g. 'charging, battery saver off'")
    p.add_argument("--skip-build", action="store_true", help="reuse the installed bench build")
    p.add_argument("--pause", type=int, default=10, help="seconds between runs")
    args = p.parse_args()

    if not args.skip_build:
        print("Building the release bench APK…")
        sh(
            [
                "flutter", "build", "apk", "--release", "-t", "lib/bench/bench_main.dart",
                f"--dart-define=BENCH_ITERATIONS={args.iterations}",
                f"--dart-define=BENCH_WARMUP={args.warmup}",
            ],
            cwd=MOBILE,
        )
        print("Installing…")
        adb(args.serial, "install", "-r", str(APK))

    device = device_facts(args.serial)
    common = {
        **git_facts(),
        "timestamp_utc": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
        "note": args.note,
    }
    print(f"Device: {device['device_manufacturer']} {device['device_model']}, "
          f"{device['ram_total_mb']} MB, API {device['android_api']}")

    rows = []
    for run in range(1, args.runs + 1):
        if run > 1:
            time.sleep(args.pause)
        results, pss_kb = one_run(args.serial, args.timeout)
        for r in results:
            row = to_row(r, device, run, common)
            row["app_pss_mb"] = round(pss_kb / 1024, 1) if pss_kb else ""
            rows.append(row)
            print(f"  run {run} {r['model']:<11} load {r['load_ms']:>8} ms  "
                  f"p50 {r['p50_us']} us  p95 {r['p95_us']} us")

    append_rows(RESULTS, rows)
    print(f"{len(rows)} rows -> {RESULTS.relative_to(ROOT)}")
    if common["git_dirty"]:
        print("Note: mobile/ had uncommitted changes; git_dirty=1 on these rows.")


if __name__ == "__main__":
    main()
