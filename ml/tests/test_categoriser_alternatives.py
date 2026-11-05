"""Checks for the categoriser alternatives in train_categoriser.py.  Run: python -m pytest ml/tests"""

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

import train_categoriser as tc  # noqa: E402

KINDS = {"food": "expense", "transport": "expense", "sales_goods": "income"}
PHRASES = {
    "food": ["lunch at the market", "nshima and beans", "tea and buns", "fritters for lunch",
             "chicken and rice", "kapenta lunch"],
    "transport": ["minibus to town", "bus fare home", "taxi to soweto", "fare to kamwala",
                  "minibus with goods", "bus to comesa"],
    "sales_goods": ["sold tomatoes", "sold two crates", "sold sugar", "sold bread to customer",
                    "sold soap", "sold mealie meal"],
}


def _corpus():
    texts, labels, groups = [], [], []
    for label, phrases in PHRASES.items():
        for t, phrase in enumerate(phrases):
            for variant in (phrase, phrase.upper(), phrase + " today", "paid " + phrase):
                texts.append(variant)
                labels.append(label)
                groups.append(f"{label}_{t}")
    return texts, labels, groups


def test_every_alternative_is_tuned_on_training_templates_and_scored():
    texts, labels, groups = _corpus()
    train = [i for i, g in enumerate(groups) if not g.endswith("_5")]
    test = [i for i, g in enumerate(groups) if g.endswith("_5")]
    out = tc.evaluate_alternatives(
        [texts[i] for i in train], [labels[i] for i in train], [groups[i] for i in train],
        [texts[i] for i in test], [labels[i] for i in test], KINDS, cutoff=0.7)
    assert list(out) == [a[0] for a in tc.ALTERNATIVES]
    for m in out.values():
        assert 0.0 <= m["test_macro_f1_all_classes"] <= 1.0
        assert 0.0 <= m["cv_macro_f1_train_templates"] <= 1.0
    assert out["lr_char_shipped"]["chosen"] == {}
    # The linear SVM gives no probabilities, so no preselection figure.
    assert out["svm_char"]["preselected_share"] is None
    assert out["lr_char_shipped"]["preselected_share"] is not None


def test_alternatives_table_names_every_method():
    texts, labels, groups = _corpus()
    out = tc.evaluate_alternatives(texts, labels, groups, texts[:12], labels[:12], KINDS, 0.7)
    text = "\n".join(tc.alternatives_text(out, 0.3))
    for name, *_ in tc.ALTERNATIVES:
        assert name in text
    assert "keyword_baseline" in text and "not evaluated" in text
