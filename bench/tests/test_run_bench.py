"""The runner's parsing and CSV rules. Inputs are made-up text in the shapes
adb prints, not measurements."""

import csv
import json
import sys
from pathlib import Path

import pytest

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))
import run_bench as rb  # noqa: E402

RESULT = {
    "model": "categoriser", "model_version": "lr-test", "model_bytes": 100,
    "load_ms": 1.5, "rss_before_load_bytes": 10 * 1024 * 1024,
    "rss_after_load_bytes": 12 * 1024 * 1024, "first_call_us": 9, "warmup": 2,
    "n": 20, "p50_us": 3, "p95_us": 5, "max_us": 6, "mean_us": 3.5,
    "inputs": 300, "build_mode": "release",
}
DEVICE = {"device_manufacturer": "Acme", "device_model": "A1", "soc": "x",
          "android_api": "30", "ram_total_mb": 2900}
COMMON = {"timestamp_utc": "2026-11-04T00:00:00Z", "git_sha": "abc1234",
          "git_dirty": 0, "note": ""}


def logcat(*payloads: str) -> str:
    return "\n".join(
        f"11-04 10:00:0{i}.123  4242  4260 I flutter : {p}" for i, p in enumerate(payloads)
    )


def test_reads_result_lines_and_the_done_marker():
    log = logcat("other output", f"SFMBENCH {json.dumps(RESULT)}", "SFMBENCH_DONE")
    results, done, errors = rb.parse_bench_lines(log)
    assert results == [RESULT]
    assert done and errors == []


def test_not_done_until_the_marker_appears():
    _, done, _ = rb.parse_bench_lines(logcat(f"SFMBENCH {json.dumps(RESULT)}"))
    assert not done


def test_an_error_on_the_phone_is_reported_not_skipped():
    _, done, errors = rb.parse_bench_lines(
        logcat("SFMBENCH error Bad state: no score", "SFMBENCH_DONE"))
    assert done and errors == ["error Bad state: no score"]


def test_pss_from_modern_and_older_dumpsys():
    assert rb.parse_pss_kb("  TOTAL PSS:    85123            TOTAL RSS:   150000") == 85123
    assert rb.parse_pss_kb("        TOTAL    61234    40000    1200") == 61234
    assert rb.parse_pss_kb("No process found") is None


def test_mem_total():
    assert rb.parse_mem_total_kb("MemTotal:        2967312 kB\nMemFree: 1 kB") == 2967312


def test_only_release_builds_become_rows():
    with pytest.raises(ValueError):
        rb.to_row({**RESULT, "build_mode": "debug"}, DEVICE, 1, COMMON)


def test_a_row_has_exactly_the_contract_columns():
    row = rb.to_row(RESULT, DEVICE, 1, COMMON)
    assert list(row) == rb.COLUMNS
    assert row["rss_after_load_mb"] == 12.0
    assert row["app_pss_mb"] == ""


def test_append_writes_the_header_once(tmp_path):
    path = tmp_path / "results.csv"
    row = rb.to_row(RESULT, DEVICE, 1, COMMON)
    rb.append_rows(path, [row])
    rb.append_rows(path, [row])
    rows = list(csv.reader(path.open(encoding="utf-8")))
    assert rows[0] == rb.COLUMNS
    assert len(rows) == 3


def test_refuses_to_append_to_a_different_csv(tmp_path):
    path = tmp_path / "results.csv"
    path.write_text("something,else\n", encoding="utf-8")
    with pytest.raises(SystemExit):
        rb.append_rows(path, [rb.to_row(RESULT, DEVICE, 1, COMMON)])
