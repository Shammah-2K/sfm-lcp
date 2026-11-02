"""Train, evaluate and export the category classifier (FR3, Chapter 3 Models and Metrics).

Reads data/processed/corpus.csv (make_corpus.py) and writes:
  out/categoriser_metrics.txt / .json   held-out-template evaluation (see below)
  out/categoriser.json                  everything the Dart categoriser needs
  out/categoriser_parity.json           300 descriptions with scikit-learn's probabilities
and copies the model into mobile/assets/models/ and the parity cases into
mobile/test/fixtures/.

Evaluation, all on the same split by template (a held-out template is a phrasing the
model never saw; a row-level split would score memorisation):
  * keyword baseline, learned from the training templates only (the floor in
    Chapter 3's models table and the "> keyword baseline" criterion);
  * TF-IDF (char_wb 2-4) + logistic regression, the main candidate;
  * macro-F1 over all 11 classes (Chapter 3's metric) and within the entry's kind
    (sale or expense), which is what the app does: the user has already chosen
    Sale or Expense when the suggestion is shown;
  * confusion matrix; coverage and accuracy at candidate confidence cutoffs.
The data are synthetic (make_corpus.py): report these as template-generalisation
results, not as accuracy on real trader descriptions.

    python train_categoriser.py [--cutoff 0.6]
"""

from __future__ import annotations

import argparse
import csv
import json
import random
import re
import shutil
from collections import Counter, defaultdict
from pathlib import Path

import numpy as np
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.linear_model import LogisticRegression
from sklearn.metrics import classification_report, confusion_matrix, f1_score
from sklearn.model_selection import GroupShuffleSplit
from sklearn.pipeline import Pipeline

from make_corpus import codebook, typo

HERE = Path(__file__).parent
CORPUS = HERE / "data" / "processed" / "corpus.csv"
OUT = HERE / "out"
MOBILE = HERE.parent / "mobile"

MODEL_NAME = "lr-v2"
NGRAM_MIN, NGRAM_MAX = 2, 4
SPLIT_TRIES = 500
TEST_SIZE = 0.2
PARITY_FROM_CORPUS = 200
PARITY_UNSEEN_TYPOS = 80
CUTOFFS = [0.4, 0.5, 0.6, 0.7, 0.8, 0.9]

EDGE_CASES = [
    "lunch", "ZESCO", "PAID THE GUARD", "bus fare!!!", "K50 airtime?", "12345",
    "  tomatoes   from   soweto  ", "\ttea\nand  buns", "a", "x y z", "qqqq zzzz",
    "rent, levy & fees", "mealie-meal 25kg", "chitenge/salaula", "café lunch",
    "MTN 2GB bundle 30 days", "Shoprite", "salary",
    "sold 3 crates of eggs and 2 dozen of bread to a customer from Matero market who will pay "
    "the balance next week on Friday",
    "bought charcoal, cooking oil, sugar, salt and soap for the shop at Comesa market then took "
    "a minibus back to Kalingalinga with all of the goods",
]


# ---------------------------------------------------------------- data and split

def load_corpus():
    with CORPUS.open(encoding="utf-8", newline="") as f:
        rows = list(csv.DictReader(f))
    provenance = {r["provenance"] for r in rows}
    return ([r["text"] for r in rows], [r["category"] for r in rows],
            [r["template_id"] for r in rows], provenance)


def split_by_template(texts, labels, groups):
    """Hold out whole templates; redraw until every category is in both halves."""
    categories = set(labels)
    splitter = GroupShuffleSplit(n_splits=SPLIT_TRIES, test_size=TEST_SIZE, random_state=42)
    for attempt, (train, test) in enumerate(splitter.split(texts, labels, groups), start=1):
        if {labels[i] for i in test} == categories and {labels[i] for i in train} == categories:
            return attempt, train, test
    raise SystemExit(f"no split in {SPLIT_TRIES} draws has every category in both halves")


# ------------------------------------------------------------------- models

def char_wb(text: str, lo: int = NGRAM_MIN, hi: int = NGRAM_MAX) -> list[str]:
    """Reference char_wb analyzer that the Dart categoriser reimplements."""
    text = re.sub(r"\s+", " ", text.lower())
    out = []
    for w in text.split(" "):
        if not w:
            continue
        p = " " + w + " "
        for n in range(lo, hi + 1):
            if len(p) <= n:
                out.append(p)
                break
            out.extend(p[i:i + n] for i in range(len(p) - n + 1))
    return out


def make_pipeline() -> Pipeline:
    return Pipeline([
        ("tfidf", TfidfVectorizer(
            analyzer="char_wb", ngram_range=(NGRAM_MIN, NGRAM_MAX), lowercase=True,
            sublinear_tf=True, min_df=2, max_features=6000,
        )),
        ("clf", LogisticRegression(max_iter=2000, C=4.0)),
    ])


_WORD = re.compile(r"[a-z]{3,}")


class KeywordBaseline:
    """Floor baseline: words seen in only one category's training rows vote for it.

    Learned from the training split only, so it is not tuned on the test templates.
    No matching word: the most common training category.
    """

    def fit(self, texts, labels):
        by_word = defaultdict(Counter)
        for text, label in zip(texts, labels):
            for word in set(_WORD.findall(text.lower())):
                by_word[word][label] += 1
        self.keywords = {w: c.most_common(1)[0][0] for w, c in by_word.items() if len(c) == 1}
        self.default = Counter(labels).most_common(1)[0][0]
        return self

    def predict(self, texts):
        out = []
        for text in texts:
            votes = Counter(self.keywords[w] for w in _WORD.findall(text.lower())
                            if w in self.keywords)
            out.append(votes.most_common(1)[0][0] if votes else self.default)
        return out


def restrict_to_kind(proba, classes, kinds_of_rows, kinds):
    """The app's suggestion: zero the other kind's classes, then renormalise."""
    mask = np.array([[kinds[c] == k for c in classes] for k in kinds_of_rows], dtype=float)
    p = proba * mask
    return p / p.sum(axis=1, keepdims=True)


# --------------------------------------------------------------- evaluation

def evaluate(texts, labels, groups, kinds, model_version):
    attempt, train, test = split_by_template(texts, labels, groups)
    tr_x, tr_y = [texts[i] for i in train], [labels[i] for i in train]
    te_x, te_y = [texts[i] for i in test], [labels[i] for i in test]

    baseline = KeywordBaseline().fit(tr_x, tr_y)
    base_pred = baseline.predict(te_x)

    model = make_pipeline().fit(tr_x, tr_y)
    classes = list(model.classes_)
    proba = model.predict_proba(te_x)
    pred = [classes[i] for i in proba.argmax(axis=1)]
    within = restrict_to_kind(proba, classes, [kinds[y] for y in te_y], kinds)
    pred_within = [classes[i] for i in within.argmax(axis=1)]
    confidence = within.max(axis=1)

    cutoffs = []
    for c in CUTOFFS:
        chosen = confidence >= c
        n = int(chosen.sum())
        correct = sum(1 for i in np.flatnonzero(chosen) if pred_within[i] == te_y[i])
        cutoffs.append({"cutoff": c, "preselected_share": n / len(te_y),
                        "accuracy_when_preselected": (correct / n) if n else None})

    metrics = {
        "model_version": model_version,
        "data": "synthetic, template-generated (make_corpus.py); held-out templates",
        "split": {"method": "GroupShuffleSplit by template_id", "test_size": TEST_SIZE,
                  "random_state": 42, "draw": attempt,
                  "train_rows": len(train), "test_rows": len(test),
                  "train_templates": sorted({groups[i] for i in train}),
                  "test_templates": sorted({groups[i] for i in test})},
        "macro_f1": {
            "keyword_baseline": f1_score(te_y, base_pred, average="macro"),
            "tfidf_lr_all_classes": f1_score(te_y, pred, average="macro"),
            "tfidf_lr_within_kind": f1_score(te_y, pred_within, average="macro"),
        },
        "confidence_cutoffs_within_kind": cutoffs,
        "classes": classes,
        "confusion_matrix_all_classes": confusion_matrix(te_y, pred, labels=classes).tolist(),
    }
    report = classification_report(te_y, pred, digits=4, zero_division=0)
    return metrics, report


def metrics_text(m, report) -> str:
    f = m["macro_f1"]
    lines = [
        f"model_version: {m['model_version']}",
        f"data: {m['data']}",
        f"split: {m['split']['method']}, test_size={m['split']['test_size']}, "
        f"random_state=42, draw {m['split']['draw']}",
        f"train rows: {m['split']['train_rows']}  test rows: {m['split']['test_rows']}",
        "",
        "macro-F1 on held-out templates:",
        f"  keyword baseline (all classes):   {f['keyword_baseline']:.4f}",
        f"  TF-IDF + LR (all classes):        {f['tfidf_lr_all_classes']:.4f}",
        f"  TF-IDF + LR (within sale/expense): {f['tfidf_lr_within_kind']:.4f}",
        "",
        "per-class, TF-IDF + LR, all classes:",
        report,
        "confusion matrix (rows = true, columns = predicted), all classes:",
        "  " + " ".join(f"{c[:6]:>6}" for c in m["classes"]),
    ]
    for c, row in zip(m["classes"], m["confusion_matrix_all_classes"]):
        lines.append(f"{c[:6]:>6} " + " ".join(f"{v:>6}" for v in row))
    lines += ["", "confidence cutoff (within kind): share preselected, accuracy when preselected"]
    for c in m["confidence_cutoffs_within_kind"]:
        acc = "-" if c["accuracy_when_preselected"] is None else f"{c['accuracy_when_preselected']:.4f}"
        lines.append(f"  {c['cutoff']:.1f}: {c['preselected_share']:.4f}  {acc}")
    lines += ["", f"test templates: {', '.join(m['split']['test_templates'])}", ""]
    return "\n".join(lines)


# ------------------------------------------------------------------- export

def parity_texts(texts):
    rng = random.Random(7)
    corpus = set(texts)
    chosen = rng.sample(texts, PARITY_FROM_CORPUS)
    unseen = []
    while len(unseen) < PARITY_UNSEEN_TYPOS:
        candidate = typo(rng.choice(texts), rng)
        if candidate not in corpus and candidate not in unseen and candidate.strip():
            unseen.append(candidate)
    cases = chosen + unseen + EDGE_CASES
    assert len(cases) == 300 and all(c.strip() for c in cases)
    return cases


def export(model: Pipeline, texts, model_version, cutoff):
    vectorizer: TfidfVectorizer = model.named_steps["tfidf"]
    clf: LogisticRegression = model.named_steps["clf"]
    cases = parity_texts(texts)
    analyzer = vectorizer.build_analyzer()
    for text in texts + cases:
        if char_wb(text) != analyzer(text):
            raise SystemExit(f"char_wb reference differs from scikit-learn on {text!r}")

    model_json = {
        "model_version": model_version,
        "analyzer": "char_wb", "ngram_min": NGRAM_MIN, "ngram_max": NGRAM_MAX,
        "lowercase": True, "sublinear_tf": True, "norm": "l2",
        "classes": [str(c) for c in clf.classes_],
        "vocabulary": {t: int(i) for t, i in sorted(vectorizer.vocabulary_.items(), key=lambda kv: kv[1])},
        "idf": [float(v) for v in vectorizer.idf_],
        "coef": [[float(v) for v in row] for row in clf.coef_],
        "intercept": [float(v) for v in clf.intercept_],
        "confidence_cutoff": cutoff,
    }
    probabilities = model.predict_proba(cases)
    assert np.allclose(probabilities.sum(axis=1), 1.0)
    parity = {
        "model_version": model_version,
        "classes": model_json["classes"],
        "cases": [{"text": t, "proba": [float(p) for p in row]} for t, row in zip(cases, probabilities)],
    }
    OUT.mkdir(exist_ok=True)
    model_path = OUT / "categoriser.json"
    parity_path = OUT / "categoriser_parity.json"
    model_path.write_text(json.dumps(model_json, ensure_ascii=False, separators=(",", ":")),
                          encoding="utf-8")
    parity_path.write_text(json.dumps(parity, ensure_ascii=False, indent=1), encoding="utf-8")
    (MOBILE / "assets" / "models").mkdir(parents=True, exist_ok=True)
    (MOBILE / "test" / "fixtures").mkdir(parents=True, exist_ok=True)
    shutil.copyfile(model_path, MOBILE / "assets" / "models" / "categoriser.json")
    shutil.copyfile(parity_path, MOBILE / "test" / "fixtures" / "categoriser_parity.json")
    size = model_path.stat().st_size
    print(f"model: {size} bytes ({size / 1e6:.2f} MB; Chapter 3 limit 5 MB), "
          f"{len(model_json['vocabulary'])} features, {len(model_json['classes'])} classes")


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--cutoff", type=float, default=0.6,
                        help="confidence at or above which the app preselects the suggestion")
    args = parser.parse_args()

    texts, labels, groups, provenance = load_corpus()
    draft = any(p.endswith("-draft") for p in provenance)
    model_version = MODEL_NAME + ("-draft" if draft else "")
    kinds = codebook()

    metrics, report = evaluate(texts, labels, groups, kinds, model_version)
    OUT.mkdir(exist_ok=True)
    (OUT / "categoriser_metrics.json").write_text(json.dumps(metrics, indent=1), encoding="utf-8")
    text = metrics_text(metrics, report)
    (OUT / "categoriser_metrics.txt").write_text(text, encoding="utf-8", newline="\n")
    print(text)

    final = make_pipeline().fit(texts, labels)  # the shipped model learns every template
    export(final, texts, model_version, args.cutoff)
    if draft:
        print("NOTE: trained on unreviewed templates; model_version is marked -draft")


if __name__ == "__main__":
    main()
