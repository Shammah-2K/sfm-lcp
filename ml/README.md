# ML pipeline (Phase 6)

Decided 2 Nov 2026: the models train on **synthetic data** (approved by the supervisor; no seed
data is collected). Claude Code builds the engineering; **Shammah reviews the templates, runs
training and evaluation, and writes up the results.**

```
templates/categoriser_templates.yaml   templates and word lists (draft: review and edit)
make_corpus.py                         templates -> data/processed/corpus.csv
train_categoriser.py                   evaluate, then export the model to the app
make_amounts.py                        synthetic ledgers with injected slips -> data/processed/amounts.csv
anomaly_features.py                    the detector's features (the phone computes the same)
train_detector.py                      Isolation Forest: evaluate, then export to the app
tests/                                 pytest checks for the generators and features
out/                                   metrics and models written by training (yours to commit)
```

## The anomaly detector

`make_amounts.py` writes 80 synthetic traders over 90 days. Each has a usual amount per category,
and about 2% of entries are replaced by a typing slip: an extra zero (×10, ×100), a dropped zero
(÷10) or a misplaced decimal point (÷100). **The amount scales and frequencies at the top of the
file are assumptions to check** against what Lusaka traders spend and earn.

`train_detector.py` computes each entry's features from that trader's *earlier* entries in the same
category only (as the phone does), fits an Isolation Forest on 75% of traders (labels unused),
chooses the flagging threshold on those traders, and reports precision, recall and recall per kind
of slip on the other 25%. It also scores five simple rules on the same held-out entries, history
and split (times the median, fixed at 5× and tuned; robust z, tuned; mean ± SD on raw amounts,
fixed at 3 and tuned), with tuned cut-offs chosen on the training traders as the forest's is, and
prints them in a comparison table beside the forest. The rules are evaluated only, never exported.
Run: `.venv/Scripts/python make_amounts.py` then
`.venv/Scripts/python train_detector.py`, then in `mobile/`
`flutter test test/domain/detector_parity_test.dart`.

## Your workflow

1. **Review the templates.** Edit `templates/categoriser_templates.yaml`: every template and every
   word list, from your knowledge of Lusaka traders. Add phrasings, remove unrealistic ones, and
   check the category of each (e.g. are school fees or medicine business expenses in your codebook?).
   Then set `reviewed: true`. Until then every row is marked `templates-v2-draft` and the model
   `lr-v2-draft`.
2. **Generate:** `.venv/Scripts/python make_corpus.py`
3. **Train and evaluate:** `.venv/Scripts/python train_categoriser.py --cutoff 0.7` (0.7 is the
   cutoff the shipped model uses)
   It prints and writes `out/categoriser_metrics.txt`: macro-F1 of the keyword baseline and of
   TF-IDF + logistic regression on held-out templates (all classes, and within sale/expense, which
   is what the app does), the confusion matrix, and how many suggestions would be preselected, and
   how accurately, at each confidence cutoff. Choose `--cutoff` from that table. It then compares
   alternatives on the same held-out templates: word TF-IDF + LR, linear SVM, Complement and
   Multinomial Naive Bayes, and the shipped LR with other n-grams and C, each tuned by grouped
   cross-validation on the training templates only (about a minute; `--skip-alternatives` skips
   it). The alternatives are evaluated only; the exported model is always lr-v2.
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
