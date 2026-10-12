"""Train, evaluate and export the prototype category classifier.

Reads data/corpus.csv (from make_corpus.py) and writes:
  out/metrics.txt              macro-F1 and per-class F1 on held-out templates
  out/categoriser_model.json   everything the Dart categoriser needs to reproduce predict_proba
  out/parity_cases.json        300 descriptions with the Python probability vector for each
and copies the model and parity file into the Flutter app.

    python train.py
"""

import csv
import json
import random
import re
import shutil
from pathlib import Path

import numpy as np
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.linear_model import LogisticRegression
from sklearn.metrics import classification_report, f1_score
from sklearn.model_selection import GroupShuffleSplit
from sklearn.pipeline import Pipeline

from make_corpus import typo

HERE = Path(__file__).parent
CORPUS = HERE / "data" / "corpus.csv"
OUT = HERE / "out"
APP = HERE.parent / "app"

MODEL_VERSION = "proto-lr-1"
CONFIDENCE_CUTOFF = 0.6
NGRAM_MIN, NGRAM_MAX = 2, 4
SPLIT_TRIES = 200
PARITY_FROM_CORPUS = 200
PARITY_UNSEEN_TYPOS = 80

EDGE_CASES = [
    "lunch",
    "ZESCO",
    "PAID THE GUARD",
    "bus fare!!!",
    "K50 airtime?",
    "12345",
    "  tomatoes   from   soweto  ",
    "\ttea\nand  buns",
    "a",
    "x y z",
    "qqqq zzzz",
    "rent, levy & fees",
    "mealie-meal 25kg",
    "chitenge/salaula",
    "café lunch",
    "MTN 2GB bundle 30 days",
    "Shoprite",
    "salary",
    "sold 3 crates of eggs and 2 dozen of bread to a customer from Matero market who will pay "
    "the balance next week on Friday",
    "bought charcoal, cooking oil, sugar, salt and soap for the shop at Comesa market then took "
    "a minibus back to Kalingalinga with all of the goods",
]


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


def load_corpus() -> tuple[list[str], list[str], list[str]]:
    with CORPUS.open(encoding="utf-8", newline="") as f:
        rows = list(csv.DictReader(f))
    return [r["text"] for r in rows], [r["category"] for r in rows], [r["template_id"] for r in rows]


def make_pipeline() -> Pipeline:
    return Pipeline([
        ("tfidf", TfidfVectorizer(
            analyzer="char_wb", ngram_range=(NGRAM_MIN, NGRAM_MAX), lowercase=True,
            sublinear_tf=True, min_df=2, max_features=6000,
        )),
        ("clf", LogisticRegression(max_iter=2000, C=4.0)),
    ])


def split_by_template(texts, labels, groups):
    # Rows from one template share their wording, so a row-level split would put near-copies of
    # every test sentence in the training set and score memorisation. Holding out whole templates
    # measures whether the model generalises to phrasings it has never seen.
    categories = set(labels)
    splitter = GroupShuffleSplit(n_splits=SPLIT_TRIES, test_size=0.2, random_state=42)
    for attempt, (train_idx, test_idx) in enumerate(splitter.split(texts, labels, groups), start=1):
        if {labels[i] for i in test_idx} == categories and {labels[i] for i in train_idx} == categories:
            return attempt, train_idx, test_idx
    raise SystemExit(f"no template split in {SPLIT_TRIES} tries has every category in both halves")


def evaluate(texts, labels, groups) -> str:
    attempt, train_idx, test_idx = split_by_template(texts, labels, groups)
    model = make_pipeline().fit([texts[i] for i in train_idx], [labels[i] for i in train_idx])
    y_true = [labels[i] for i in test_idx]
    y_pred = model.predict([texts[i] for i in test_idx])
    macro = f1_score(y_true, y_pred, average="macro")
    report = classification_report(y_true, y_pred, digits=4, zero_division=0)
    train_templates = sorted({groups[i] for i in train_idx})
    test_templates = sorted({groups[i] for i in test_idx})
    return "\n".join([
        f"model_version: {MODEL_VERSION}",
        f"split: GroupShuffleSplit by template_id, test_size=0.2, random_state=42, draw {attempt}",
        f"train rows: {len(train_idx)}  test rows: {len(test_idx)}",
        f"macro-F1 (held-out templates): {macro:.4f}",
        "",
        "per-class (held-out templates):",
        report,
        f"train templates ({len(train_templates)}): {', '.join(train_templates)}",
        f"test templates ({len(test_templates)}): {', '.join(test_templates)}",
        "",
    ])


def parity_texts(texts: list[str]) -> list[str]:
    rng = random.Random(7)
    corpus_set = set(texts)
    chosen = rng.sample(texts, PARITY_FROM_CORPUS)
    unseen = []
    while len(unseen) < PARITY_UNSEEN_TYPOS:
        candidate = typo(rng.choice(texts), rng)
        if candidate not in corpus_set and candidate not in unseen and candidate.strip():
            unseen.append(candidate)
    cases = chosen + unseen + EDGE_CASES
    assert len(cases) == 300 and all(c.strip() for c in cases)
    return cases


def export(model: Pipeline, texts: list[str]) -> None:
    vectorizer: TfidfVectorizer = model.named_steps["tfidf"]
    clf: LogisticRegression = model.named_steps["clf"]

    cases = parity_texts(texts)
    analyzer = vectorizer.build_analyzer()
    for text in texts + cases:
        if char_wb(text) != analyzer(text):
            raise SystemExit(f"char_wb reference differs from scikit-learn on {text!r}")

    model_json = {
        "model_version": MODEL_VERSION,
        "analyzer": "char_wb", "ngram_min": NGRAM_MIN, "ngram_max": NGRAM_MAX,
        "lowercase": True, "sublinear_tf": True, "norm": "l2",
        "classes": [str(c) for c in clf.classes_],
        "vocabulary": {term: int(i) for term, i in sorted(vectorizer.vocabulary_.items(), key=lambda kv: kv[1])},
        "idf": [float(v) for v in vectorizer.idf_],
        "coef": [[float(v) for v in row] for row in clf.coef_],
        "intercept": [float(v) for v in clf.intercept_],
        "confidence_cutoff": CONFIDENCE_CUTOFF,
    }
    probabilities = model.predict_proba(cases)
    parity = {
        "model_version": MODEL_VERSION,
        "classes": model_json["classes"],
        "cases": [
            {"text": text, "proba": [float(p) for p in row]}
            for text, row in zip(cases, probabilities)
        ],
    }
    assert np.allclose(probabilities.sum(axis=1), 1.0)

    OUT.mkdir(exist_ok=True)
    model_path = OUT / "categoriser_model.json"
    parity_path = OUT / "parity_cases.json"
    model_path.write_text(json.dumps(model_json, ensure_ascii=False, separators=(",", ":")), encoding="utf-8")
    parity_path.write_text(json.dumps(parity, ensure_ascii=False, indent=1), encoding="utf-8")

    (APP / "assets" / "models").mkdir(parents=True, exist_ok=True)
    (APP / "test" / "fixtures").mkdir(parents=True, exist_ok=True)
    shutil.copyfile(model_path, APP / "assets" / "models" / "categoriser_model.json")
    shutil.copyfile(parity_path, APP / "test" / "fixtures" / "parity_cases.json")
    print(f"model: {model_path.stat().st_size} bytes, {len(model_json['vocabulary'])} features, "
          f"{len(model_json['classes'])} classes")


def main() -> None:
    texts, labels, groups = load_corpus()
    metrics = evaluate(texts, labels, groups)
    OUT.mkdir(exist_ok=True)
    (OUT / "metrics.txt").write_text(metrics, encoding="utf-8", newline="\n")
    print(metrics)
    final = make_pipeline().fit(texts, labels)
    export(final, texts)


if __name__ == "__main__":
    main()
