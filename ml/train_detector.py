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
    best = (0.0, 0.5)
    for th in np.unique(np.round(scores, 4)):
        p, r, f, _ = precision_recall_fscore_support(labels, scores >= th, average="binary",
                                                     zero_division=0)
        if f > best[0]:
            best = (f, float(th))
    return best[1]


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
