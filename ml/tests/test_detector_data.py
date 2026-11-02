"""Checks for make_amounts.py and anomaly_features.py.  Run: python -m pytest ml/tests"""

import math
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

import anomaly_features as af  # noqa: E402
import make_amounts as ma  # noqa: E402


def test_amounts_reproducible_byte_for_byte(tmp_path):
    a, b = tmp_path / "a.csv", tmp_path / "b.csv"
    ma.write(ma.generate(), a)
    ma.write(ma.generate(), b)
    assert a.read_bytes() == b.read_bytes()


def test_amounts_are_positive_whole_ngwee_and_anomalies_are_labelled():
    rows = ma.generate()
    assert all(isinstance(r["amount_ngwee"], int) and r["amount_ngwee"] >= 50 for r in rows)
    kinds = {r["anomaly_kind"] for r in rows if r["is_anomaly"]}
    assert kinds <= set(ma.ANOMALY_KINDS) and kinds
    assert all((r["anomaly_kind"] == "") == (r["is_anomaly"] == 0) for r in rows)
    share = sum(r["is_anomaly"] for r in rows) / len(rows)
    assert 0.01 < share < 0.03


def test_type_follows_the_category_kind():
    kinds = ma.codebook()
    for r in ma.generate()[:5000]:
        assert r["type"] == ("sale" if kinds[r["category"]] == "income" else "expense")


def test_no_opinion_below_the_minimum_history():
    assert af.features(2500, [2500] * (af.MIN_HISTORY - 1)) is None
    assert af.features(2500, [2500] * af.MIN_HISTORY) is not None


def test_features_measure_distance_from_usual():
    usual = [2400, 2500, 2600, 2500, 2550]
    same = af.features(2500, usual)
    ten_times = af.features(25000, usual)
    assert abs(same[0]) < 1e-9
    assert math.isclose(ten_times[0], math.log(10), rel_tol=1e-9)
    assert ten_times[1] > 10 * abs(same[1] + 1e-9)


def test_median_matches_the_usual_definition():
    assert af.median([3, 1, 2]) == 2
    assert af.median([4, 1, 3, 2]) == 2.5
