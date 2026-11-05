"""Train, evaluate and export the anomaly detector (FR4, Chapter 3: Isolation Forest).

Reads data/processed/amounts.csv (make_amounts.py) and writes:
  out/detector_metrics.txt / .json   precision and recall on injected anomalies
  out/detector.json                  the forest, for the Dart detector
  out/detector_parity.json           entries with history, features and scores
and copies the model to mobile/assets/models/ and the parity cases to
mobile/test/fixtures/.

Method:
  * Each entry's features come only from that trader's EARLIER entries of the same
    type and category (anomaly_features.py), as on the phone.
  * Traders are split 75/25: the forest is fitted (unsupervised, labels unused) on
    the training traders; the flagging threshold is chosen on the training traders
    (best F1); precision and recall are reported on the held-out traders only.
  * The score stored on the phone is s = 2^(-E[h(x)] / c(max_samples)), between 0
    and 1, higher = more unusual (scikit-learn's -score_samples).
  * Baselines (simple rules: times the median, robust z, mean +/- SD) are scored on
    the same held-out traders with the same history, and reported beside the forest.
    They are evaluated only, never exported.

    python train_detector.py
"""

from __future__ import annotations

import bisect
import csv
import json
import math
import random
import shutil
from collections import defaultdict
from pathlib import Path

import numpy as np
from sklearn.ensemble import IsolationForest
from sklearn.metrics import precision_recall_fscore_support

from anomaly_features import FEATURES, HISTORY_DAYS, MIN_HISTORY, features

HERE = Path(__file__).parent
DATA = HERE / "data" / "processed" / "amounts.csv"
OUT = HERE / "out"
MOBILE = HERE.parent / "mobile"

MODEL_VERSION = "iforest-v1"
N_ESTIMATORS = 100
MAX_SAMPLES = 256
TEST_SHARE = 0.25
DAY_MS = 86_400_000


# ------------------------------------------------------------------ features

def feature_rows(rows):
    """One row per entry that has enough history, in time order per trader."""
    out = []
    seen = defaultdict(list)  # (trader, type, category) -> [(time, amount)]
    for r in rows:
        key = (r["trader"], r["type"], r["category"])
        t, amount = int(r["occurred_at_ms"]), int(r["amount_ngwee"])
        past = seen[key]
        start = bisect.bisect_left(past, (t - HISTORY_DAYS * DAY_MS, -1))
        history = [a for _, a in past[start:]]
        f = features(amount, history)
        if f is not None:
            out.append({"trader": r["trader"], "x": f, "label": int(r["is_anomaly"]),
                        "kind": r["anomaly_kind"], "amount": amount, "history": history})
        past.append((t, amount))
    return out


# ------------------------------------------------- the forest, reimplemented

def c(n: float) -> float:
    """Average path length of an unsuccessful search in a binary tree of n points."""
    if n <= 1:
        return 0.0
    if n <= 2:
        return 1.0
    return 2.0 * (math.log(n - 1.0) + np.euler_gamma) - 2.0 * (n - 1.0) / n


def export_trees(forest: IsolationForest):
    trees = []
    for est, cols in zip(forest.estimators_, forest.estimators_features_):
        t = est.tree_
        trees.append({
            "left": t.children_left.tolist(),
            "right": t.children_right.tolist(),
            # Each tree sees a permutation of the columns; store original column numbers.
            "feature": [int(cols[f]) if f >= 0 else -1 for f in t.feature],
            "threshold": t.threshold.tolist(),
            "n_samples": t.n_node_samples.tolist(),
        })
    return trees


def score(trees, max_samples, x) -> float:
    """Reference scorer the Dart detector reimplements. Like scikit-learn's trees,
    it compares feature values as float32."""
    x32 = [float(np.float32(v)) for v in x]
    total = 0.0
    for t in trees:
        node, depth = 0, 0
        while t["left"][node] != -1:
            node = (t["left"][node] if x32[t["feature"][node]] <= t["threshold"][node]
                    else t["right"][node])
            depth += 1
        total += depth + c(t["n_samples"][node])
    return 2.0 ** (-(total / len(trees)) / c(max_samples))


# --------------------------------------------------------------- evaluation

def best_threshold(scores, labels):
    """The candidate (scores rounded to 4 places) with the best F1 when flagging
    score >= candidate; the smallest such candidate on a tie. Vectorised, so it
    is quick on the baselines' unbounded scores too."""
    scores, labels = np.asarray(scores, dtype=float), np.asarray(labels, dtype=int)
    candidates = np.unique(np.round(scores, 4))
    order = np.argsort(scores, kind="stable")
    sorted_scores = scores[order]
    # anomalies_from[i] = anomalies among the i-th smallest score and above.
    anomalies_from = np.concatenate([np.cumsum(labels[order][::-1])[::-1], [0]])
    start = np.searchsorted(sorted_scores, candidates, side="left")
    flagged = len(scores) - start
    tp = anomalies_from[start]
    f1 = np.where(flagged > 0, 2 * tp / (flagged + labels.sum()), 0.0)
    if not len(candidates) or f1.max() <= 0:
        return 0.5
    return float(candidates[int(np.argmax(f1))])


def summarise(scores, labels, kinds, threshold):
    flagged = scores >= threshold
    p, r, f, _ = precision_recall_fscore_support(labels, flagged, average="binary",
                                                 zero_division=0)
    per_kind = {}
    for k in sorted({k for k in kinds if k}):
        idx = [i for i, kk in enumerate(kinds) if kk == k]
        per_kind[k] = {"n": len(idx), "recall": float(np.mean(flagged[idx]))}
    normal = [i for i, l in enumerate(labels) if not l]
    return {"threshold": threshold, "precision": float(p), "recall": float(r), "f1": float(f),
            "flagged_share_of_normal": float(np.mean(flagged[normal])),
            "anomalies": int(sum(labels)), "entries": len(labels),
            "recall_by_kind": per_kind}


# ---------------------------------------------------------------- baselines
#
# Simple rules the forest must beat to earn its place. Each sees exactly what
# the forest sees: the same entries, the same earlier history (same trader,
# type and category, last HISTORY_DAYS days, at least MIN_HISTORY entries) and
# the same split. A score is higher = more unusual; an entry is flagged when
# score >= threshold. "tuned" thresholds are chosen on the training traders
# (best F1), as the forest's is; "fixed" ones are a conventional value, no tuning.

def ratio_score(d) -> float:
    """How many times bigger or smaller than the median, on a log scale, either way."""
    return abs(d["x"][0])


def robust_z_score(d) -> float:
    """The same in units of this trader's usual spread (the forest's second feature)."""
    return abs(d["x"][1])


def mean_sd_score(d) -> float:
    """Classic z-score on raw amounts: distance from the mean in standard deviations.
    A constant history has no spread; a floor of 1 ngwee keeps it defined."""
    h = np.asarray(d["history"], dtype=float)
    return abs(d["amount"] - h.mean()) / max(float(h.std()), 1.0)


# (name, description, score, fixed threshold or None for tuned)
BASELINES = [
    ("ratio_5x_fixed", "more than 5 times, or under a fifth of, the median", ratio_score,
     math.log(5.0)),
    ("ratio_tuned", "times the median, either way, cut-off tuned", ratio_score, None),
    ("robust_z_tuned", "|log ratio| / trader's usual spread, cut-off tuned", robust_z_score, None),
    ("mean_3sd_fixed", "more than 3 SD from the mean (raw amounts)", mean_sd_score, 3.0),
    ("mean_sd_tuned", "SDs from the mean (raw amounts), cut-off tuned", mean_sd_score, None),
]


def evaluate_baselines(train, test):
    y_train = [d["label"] for d in train]
    y_test, kinds = [d["label"] for d in test], [d["kind"] for d in test]
    out = {}
    for name, description, fn, fixed in BASELINES:
        s_test = np.array([fn(d) for d in test])
        threshold = (fixed if fixed is not None
                     else best_threshold(np.array([fn(d) for d in train]), y_train))
        m = summarise(s_test, y_test, kinds, float(threshold))
        m["rule"] = description
        m["threshold_chosen_on"] = "fixed" if fixed is not None else "training traders, best F1"
        if name.startswith("ratio"):
            m["threshold_as_times_median"] = math.exp(threshold)
        out[name] = m
    return out


def comparison_lines(metrics):
    rows = [("isolation_forest", metrics["test"])] + list(metrics["baselines"].items())
    lines = ["comparison on the held-out traders (same entries, history and split):",
             f"  {'method':<18}{'threshold':>11}{'precision':>11}{'recall':>9}{'F1':>9}"
             f"{'normal flagged':>16}   recall x10  /10  x100 /100"]
    for name, m in rows:
        r = m["recall_by_kind"]
        per_kind = "  ".join(f"{r[k]['recall']:.3f}" if k in r else "  -  "
                             for k in ("x10", "/10", "x100", "/100"))
        lines.append(f"  {name:<18}{m['threshold']:>11.4f}{m['precision']:>11.4f}"
                     f"{m['recall']:>9.4f}{m['f1']:>9.4f}{m['flagged_share_of_normal']:>16.4f}"
                     f"   {per_kind}")
    for name, m in metrics["baselines"].items():
        extra = (f" (= {m['threshold_as_times_median']:.2f} times the median)"
                 if "threshold_as_times_median" in m else "")
        lines.append(f"  {name}: {m['rule']}; threshold {m['threshold_chosen_on']}{extra}")
    return lines


def main():
    with DATA.open(encoding="utf-8", newline="") as f:
        rows = list(csv.DictReader(f))
    data = feature_rows(rows)

    traders = sorted({d["trader"] for d in data})
    random.Random(42).shuffle(traders)
    test_traders = set(traders[: round(len(traders) * TEST_SHARE)])
    train = [d for d in data if d["trader"] not in test_traders]
    test = [d for d in data if d["trader"] in test_traders]

    forest = IsolationForest(n_estimators=N_ESTIMATORS, max_samples=MAX_SAMPLES,
                             random_state=42).fit(np.array([d["x"] for d in train]))
    trees = export_trees(forest)
    max_samples = int(forest.max_samples_)

    # The reimplementation must equal scikit-learn on every row before it is exported.
    all_x = np.array([d["x"] for d in data])
    sk = -forest.score_samples(all_x)
    ours = np.array([score(trees, max_samples, x) for x in all_x])
    worst = float(np.max(np.abs(sk - ours)))
    if worst > 1e-12:
        raise SystemExit(f"reference scorer differs from scikit-learn by {worst}")

    s_train = np.array([score(trees, max_samples, d["x"]) for d in train])
    s_test = np.array([score(trees, max_samples, d["x"]) for d in test])
    threshold = best_threshold(s_train, [d["label"] for d in train])
    metrics = {
        "model_version": MODEL_VERSION,
        "data": "synthetic ledgers with injected anomalies (make_amounts.py)",
        "features": FEATURES, "min_history": MIN_HISTORY, "history_days": HISTORY_DAYS,
        "split": {"by": "trader", "test_traders": len(test_traders),
                  "train_traders": len(traders) - len(test_traders),
                  "train_entries": len(train), "test_entries": len(test)},
        "threshold_chosen_on": "training traders, best F1",
        "test": summarise(s_test, [d["label"] for d in test], [d["kind"] for d in test], threshold),
        "test_at_0_5": summarise(s_test, [d["label"] for d in test], [d["kind"] for d in test], 0.5),
        "baselines": evaluate_baselines(train, test),
        "reference_vs_sklearn_max_abs_diff": worst,
    }
    OUT.mkdir(exist_ok=True)
    (OUT / "detector_metrics.json").write_text(json.dumps(metrics, indent=1), encoding="utf-8")
    lines = [f"model_version: {MODEL_VERSION}", f"data: {metrics['data']}",
             f"split by trader: {metrics['split']}",
             f"threshold (chosen on training traders, best F1): {threshold:.4f}", ""]
    for name in ("test", "test_at_0_5"):
        m = metrics[name]
        lines.append(f"{name}: threshold {m['threshold']:.4f}  precision {m['precision']:.4f}  "
                     f"recall {m['recall']:.4f}  F1 {m['f1']:.4f}  "
                     f"normal entries flagged {m['flagged_share_of_normal']:.4f}  "
                     f"({m['anomalies']} anomalies in {m['entries']} entries)")
        for k, v in m["recall_by_kind"].items():
            lines.append(f"    recall {k:>5}: {v['recall']:.4f} (n={v['n']})")
    lines += [""] + comparison_lines(metrics)
    text = "\n".join(lines) + "\n"
    (OUT / "detector_metrics.txt").write_text(text, encoding="utf-8", newline="\n")
    print(text)

    model = {"model_version": MODEL_VERSION, "features": FEATURES, "min_history": MIN_HISTORY,
             "history_days": HISTORY_DAYS, "max_samples": max_samples, "threshold": threshold,
             "trees": trees}
    rng = random.Random(7)
    cases = [{"amount": d["amount"], "history": d["history"], "features": d["x"],
              "score": score(trees, max_samples, d["x"])} for d in rng.sample(test, 200)]
    # Too little history: no opinion.
    cases += [{"amount": 2500, "history": [2500] * (MIN_HISTORY - 1), "features": None,
               "score": None}]
    parity = {"model_version": MODEL_VERSION, "cases": cases}
    model_path, parity_path = OUT / "detector.json", OUT / "detector_parity.json"
    model_path.write_text(json.dumps(model, separators=(",", ":")), encoding="utf-8")
    parity_path.write_text(json.dumps(parity, indent=1), encoding="utf-8")
    shutil.copyfile(model_path, MOBILE / "assets" / "models" / "detector.json")
    shutil.copyfile(parity_path, MOBILE / "test" / "fixtures" / "detector_parity.json")
    print(f"model: {model_path.stat().st_size} bytes, {len(trees)} trees; "
          f"reference vs scikit-learn max difference {worst:.2e}")


if __name__ == "__main__":
    main()
