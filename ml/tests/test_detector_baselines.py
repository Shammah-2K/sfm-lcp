"""Checks for the detector baselines in train_detector.py.  Run: python -m pytest ml/tests"""

import math
import sys
from pathlib import Path

import numpy as np
from sklearn.metrics import precision_recall_fscore_support

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

import anomaly_features as af  # noqa: E402
import train_detector as td  # noqa: E402


def _entry(amount, history, label=0):
    return {"amount": amount, "history": history, "x": af.features(amount, history),
            "label": label, "kind": "x10" if label else ""}


def _old_best_threshold(scores, labels):
    """The loop train_detector used before; the vectorised one must agree."""
    best = (0.0, 0.5)
    for th in np.unique(np.round(scores, 4)):
        _, _, f, _ = precision_recall_fscore_support(labels, scores >= th, average="binary",
                                                     zero_division=0)
        if f > best[0]:
            best = (f, float(th))
    return best[1]


def test_vectorised_threshold_matches_the_scikit_learn_loop():
    rng = np.random.default_rng(0)
    for _ in range(20):
        n = int(rng.integers(50, 400))
        labels = (rng.random(n) < 0.1).astype(int)
        scores = rng.random(n) * 0.5 + labels * rng.random(n) * 0.5
        assert td.best_threshold(scores, labels) == _old_best_threshold(scores, labels)


def test_threshold_without_anomalies_falls_back_to_one_half():
    assert td.best_threshold(np.array([0.1, 0.2, 0.3]), [0, 0, 0]) == 0.5


def test_ratio_rule_is_symmetric_for_slips_up_and_down():
    history = [2500] * 6
    up, down = _entry(25000, history), _entry(250, history)
    assert math.isclose(td.ratio_score(up), math.log(10))
    assert math.isclose(td.ratio_score(up), td.ratio_score(down))


def test_fixed_5x_rule_flags_x10_but_not_double():
    history = [2500, 2400, 2600, 2500, 2550]
    threshold = dict((b[0], b[3]) for b in td.BASELINES)["ratio_5x_fixed"]
    assert td.ratio_score(_entry(25000, history)) >= threshold
    assert td.ratio_score(_entry(5000, history)) < threshold


def test_mean_sd_is_defined_for_a_constant_history():
    assert td.mean_sd_score(_entry(2500, [2500] * 5)) == 0.0
    assert td.mean_sd_score(_entry(2600, [2500] * 5)) == 100.0


def test_every_baseline_is_reported_with_its_rule():
    history = [2500, 2400, 2600, 2500, 2550, 2450]
    train = [_entry(2500, history) for _ in range(30)] + [_entry(25000, history, 1)] * 3
    test = [_entry(2480, history) for _ in range(20)] + [_entry(250, history, 1)] * 2
    out = td.evaluate_baselines(train, test)
    assert set(out) == {b[0] for b in td.BASELINES}
    for m in out.values():
        assert m["rule"] and 0.0 <= m["f1"] <= 1.0
    # Trained on x10 slips, tested on /10: the log-scale rules are symmetric and
    # catch them; mean +/- SD on raw amounts, tuned on far-off x10s, does not.
    assert out["ratio_tuned"]["recall"] == 1.0
    assert out["ratio_5x_fixed"]["recall"] == 1.0
    assert out["mean_sd_tuned"]["recall"] == 0.0
