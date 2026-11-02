# ML pipeline (Phase 6)

Decided 2 Nov 2026: the models train on **synthetic data** (approved by the supervisor; no seed
data is collected). Claude Code builds the engineering; **Shammah reviews the templates, runs
training and evaluation, and writes up the results.**

```
templates/categoriser_templates.yaml   templates and word lists (draft: review and edit)
make_corpus.py                         templates -> data/processed/corpus.csv
train_categoriser.py                   evaluate, then export the model to the app
tests/                                 pytest checks for the generator
out/                                   metrics and model written by training (yours to commit)
```

## Your workflow

1. **Review the templates.** Edit `templates/categoriser_templates.yaml`: every template and every
   word list, from your knowledge of Lusaka traders. Add phrasings, remove unrealistic ones, and
   check the category of each (e.g. are school fees or medicine business expenses in your codebook?).
   Then set `reviewed: true`. Until then every row is marked `templates-v2-draft` and the model
   `lr-v2-draft`.
2. **Generate:** `.venv/Scripts/python make_corpus.py`
3. **Train and evaluate:** `.venv/Scripts/python train_categoriser.py --cutoff 0.6`
   It prints and writes `out/categoriser_metrics.txt`: macro-F1 of the keyword baseline and of
   TF-IDF + logistic regression on held-out templates (all classes, and within sale/expense, which
   is what the app does), the confusion matrix, and how many suggestions would be preselected, and
   how accurately, at each confidence cutoff. Choose `--cutoff` from that table.
4. **Check the app still matches:** in `mobile/`, `flutter test test/domain/categoriser_parity_test.dart`
   (Dart must equal scikit-learn within 1e-6 on 300 cases).
5. Record the run in the AI assistance log and commit `out/`, the YAML, the corpus and the model.

Set-up: `python -m venv .venv` then `.venv/Scripts/python -m pip install -r requirements-pipeline.txt`.
Tests: `.venv/Scripts/python -m pytest tests`.

## What the numbers can claim

Training and test data come from the same generator, but the test templates are held out, so the
score measures generalisation to **unseen phrasings**, not accuracy on real trader descriptions.
Chapter 3's threshold "Macro-F1 (real held-out set) ≥ 0.80" cannot be measured without real data:
report it as not measurable in this study, alongside the synthetic result, with the claim limits
Chapter 3 already states. Efficiency (latency, RAM, size, load time) is fully measurable on
synthetic data.
