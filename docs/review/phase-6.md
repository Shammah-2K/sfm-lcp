# Review guide — Phase 6: the on-device categoriser and anomaly detector

Branch `feature/ml`. Written by Claude Code under the 25 Oct 2026 working agreement, extended on
2 Nov 2026: the models train on **synthetic data** (approved by the supervisor), Claude Code builds
the engineering, and Shammah reviews the templates, runs training and evaluation, and writes up
the results. Record all four commits in the AI assistance log:

| Commit | What |
|---|---|
| `c0c3e64` | Synthetic corpus, training pipeline and the on-device categoriser (FR3) |
| `d8b145a` | Synthetic ledgers, Isolation Forest training and the on-device detector (FR4) |
| `8e8eb23` | The on-device benchmark harness (NFR1, NFR2) |
| `b4483af` | Researcher mode (D8) |

**State on 4 Nov 2026:** you have reviewed `ml/templates/categoriser_templates.yaml` and set
`reviewed: true`. The model bundled in the app is still **`lr-v2-draft`**, trained before your
review, and so are the figures in `ml/out/`. Retrain (section 6) and both become `lr-v2`. The
benchmark has not been run on a phone yet, so no efficiency figures exist.

## 1. What changed for the user

| Change | Requirement |
|---|---|
| Typing a description on a sale or expense suggests a category within a moment. A confident suggestion is selected for the user; an unsure one offers three to pick from | FR3, UC5 |
| The suggestion reads "Suggested on this phone", with no percentage | D8 |
| An amount far from the trader's usual one for that category gets the "Is this right? Usually about K…" check | FR4, UC4 |
| A new trader (fewer than 5 earlier entries in a category) is never asked | FR4 |
| If a model file can't be loaded, the app still works: the user picks every category and nothing is flagged | FR8 |
| Long-pressing the participant code turns researcher mode on or off for the session: confidence, time taken and model version under each suggestion | D8 |

Both models run on the phone. No description or amount leaves it for inference.

## 2. Read in this order

1. `ml/README.md`: the pipeline and your workflow.
2. `ml/make_corpus.py` with `ml/templates/categoriser_templates.yaml`: how descriptions are generated.
3. `ml/train_categoriser.py`: the module docstring first, then `evaluate` and `export`.
4. `mobile/lib/domain/tfidf_categoriser.dart`: the same model in Dart.
5. `ml/make_amounts.py`, `ml/anomaly_features.py`, `ml/train_detector.py`: the detector's data,
   features and training.
6. `mobile/lib/domain/isolation_forest_detector.dart`.
7. `mobile/lib/main.dart` (`_loadCategoriser`, `_loadDetector`) and
   `mobile/lib/data/ledger_repository.dart` (`record`, `_history`, `watchNeedsCheck`): where the
   models are used.
8. `bench/README.md`, then `mobile/lib/bench/benchmark.dart` and `bench/run_bench.py`.
9. `mobile/lib/app/researcher_mode.dart`, then the code pill in `tab_scaffold.dart` and
   `_CategoryChoice` in `entry_screen.dart`.

## 3. The categoriser (FR3)

### 3.1 Data

`make_corpus.py` fills each template's `{slots}` from the word lists, 120 rows per template, with
seed 42 so the corpus is the same every run. It adds noise a phone keyboard produces: a typo in
30% of rows (a dropped, swapped or doubled letter, never the first), random case in 10%, and an
amount typed into the text in 10%. Category codes are checked against the codebook in the server
migration, so a template cannot invent a category. Each row's `provenance` is the template file's
version, with `-draft` added while `reviewed` is false.

### 3.2 The split: why by template

Rows from one template are near-copies. A random row split would put copies of the same phrasing
in both halves, and the score would measure memorisation. `split_by_template` holds out whole
templates (20%), redrawing until every category appears on both sides. The score therefore
measures how well the model handles **phrasings it never saw**. It does not measure accuracy on
real traders' words (section 8).

### 3.3 The model

TF-IDF over character 2–4-grams within word boundaries (`char_wb`), then multinomial logistic
regression. Character n-grams tolerate typos and run-together words ("atChaisa"), which word
features would miss. It is compared with a keyword baseline learned from the training templates
only, the floor in Chapter 3's models table.

Two macro-F1 figures are reported. **All classes** is Chapter 3's metric. **Within kind** is
what the app does: the user has already pressed Sale or Expense, so the other kind's categories
are dropped and the rest renormalised (`restrict_to_kind` in Python, `suggest` in Dart). Check
that Chapter 4 says which figure is which.

### 3.4 The cutoff

At or above `--cutoff` the app preselects the top category; below it, it shows three. The metrics
file has a table of how many suggestions would be preselected, and how many of those would be
right, at 0.4–0.9. **Choosing the cutoff is your decision.** It trades taps saved against wrong
categories accepted. Write down why you chose it.

### 3.5 The shipped model learns every template

The evaluation model is trained on the training templates only. The exported model is refitted on
all of them (`final = make_pipeline().fit(texts, labels)`), because the evaluation has already
estimated how well that method generalises. This is standard practice, but Chapter 4 should
say it.

### 3.6 Parity: why the Dart model can be trusted

The Dart code reimplements scikit-learn; it is not a library. Three checks tie them together:
- `export` refuses to write the model if a Python reference of `char_wb` differs from
  scikit-learn's analyzer on any text.
- 300 descriptions (200 from the corpus, 80 with new typos, and fixed edge cases) are exported
  with scikit-learn's probabilities.
- `categoriser_parity_test.dart` checks Dart gives the same probabilities **within 1e-6** on all
  300. It runs in CI on every push (NFR8).

## 4. The anomaly detector (FR4)

### 4.1 Data

`make_amounts.py` simulates 80 traders over 90 days. Each trader has a usual amount per category,
drawn from log-normal spreads (`BETWEEN_TRADER_SIGMA`, `WITHIN_TRADER_SIGMA`). About 2% of entries
are replaced with a labelled typing slip: an extra zero (×10, ×100), a dropped zero (÷10) or a
misplaced decimal point (÷100). **The amount scales and frequencies at the top of the file are
assumptions. Check them against what Lusaka traders actually earn and spend.**

### 4.2 Features

`anomaly_features.py` and `features()` in Dart compute the same two numbers from the trader's
**earlier** entries of the same type and category within 60 days:
- `log_ratio`: log(amount) minus the median log of the history ("how many times bigger than usual").
- `robust_z`: the same distance in units of the trader's spread (1.4826 × MAD, floored at 0.05),
  so a trader whose amounts always vary is not flagged for normal variation.

Fewer than 5 earlier entries means no features and no opinion.

### 4.3 Training and threshold

Traders are split 75/25. The Isolation Forest (100 trees, 256 samples each) is fitted on the
training traders' features **without labels**, which keeps it unsupervised as Chapter 3 states.
The labels are used twice: once to choose the flagging threshold on the training traders (best
F1), and once to report precision and recall on the held-out traders, overall and per kind of slip.

### 4.4 Parity

scikit-learn compares features as float32 inside its trees, and the Dart detector does the same.
`train_detector.py` refuses to export unless its own reference scorer equals scikit-learn on every
row. `detector_parity_test.dart` then checks features and scores against Python **within 1e-12**.

### 4.5 "Usually about K…"

`typicalNgwee` is the median amount of that category in the history, given from 3 entries. It is
plain arithmetic, not the forest, and is what the user sees beside the check.

## 5. The benchmark harness (NFR1, NFR2)

Read `bench/README.md` for how to run it and what each column means. Choices to check:

- **Release build only.** It is a separate entrypoint (`lib/bench/bench_main.dart`), built with
  `flutter build apk --release -t …`. The runner refuses rows that aren't from a release build.
  The app's own `main.dart` never imports the bench code, so it adds nothing to the real APK.
- **What is timed** is the public call the app makes (`suggest`, `score`), after 100 untimed
  warm-up calls, over 1000 calls. The first call is reported separately, and load time is the
  cold asset read plus parse.
- **Percentiles are nearest-rank,** so every p50 and p95 is a value that was actually observed.
- **Inputs:** the categoriser cycles through the 300 held-out parity descriptions
  (`bench/make_bench_texts.py` copies them into the bench build; rerun it after retraining). The
  detector scores 200 entries against a fixed synthetic trader with about 1,140 entries over the
  60-day window. The database query is not included.
- **Memory:** `app_pss_mb` from `dumpsys meminfo` is the figure to report. The RSS before and
  after loading is indicative only, because garbage collection moves it.
- **No thresholds in code.** Compare the results against Chapter 3's NFR1 and NFR2 in the
  write-up.

## 6. Your runs

1. Done: templates reviewed.
2. `cd ml`, then `.venv/Scripts/python make_corpus.py` and
   `.venv/Scripts/python train_categoriser.py --cutoff <yours>`. The model version should now print
   without `-draft`.
3. `.venv/Scripts/python make_amounts.py` and `.venv/Scripts/python train_detector.py`, once you
   have checked the amount assumptions.
4. `python bench/make_bench_texts.py` from the repository root, then in `mobile/`
   `flutter test`. The parity tests must pass against the new models.
5. Commit `ml/out/`, the YAML, the regenerated assets and fixtures, and `bench_texts.dart`.
6. On both test phones: `ml/.venv/Scripts/python bench/run_bench.py --note "…"`, then
   `plot_bench.py`. Commit `bench/results.csv` and `docs/bench/`.

## 7. Tests

| Test | Rule |
|---|---|
| `categoriser_parity_test`: probabilities match within 1e-6 on all 300 cases | Dart = scikit-learn (NFR8) |
| `categoriser_parity_test`: suggestions stay within the entry kind and sum to 1 there | Within-kind suggestion |
| `categoriser_parity_test`: preselect follows the model cutoff | §3.4 |
| `categoriser_parity_test`: a blank description gives no suggestion | UC5 |
| `detector_parity_test`: features and scores match Python within 1e-12 | Dart = scikit-learn (NFR8) |
| `detector_parity_test`: an extra zero is flagged; the usual amount is not | FR4 |
| `detector_parity_test`: other categories and too little history give no opinion | §4.2 |
| `detector_parity_test`: "usually about" is the median of the category, from 3 entries | §4.5 |
| `ml/tests/test_make_corpus.py` (8 tests): reproducible byte for byte, codebook kinds, no unfilled slots or duplicates, draft marking, typo rules | §3.1 |
| `ml/tests/test_detector_data.py` (6 tests): reproducible, labelled anomalies, kinds, minimum history, features | §4.1–4.2 |
| `test/bench/benchmark_test.dart`: nearest-rank percentiles, fixed inputs, a full run prints one line per model | §5 |
| `bench/tests/test_run_bench.py` (9 tests): logcat and dumpsys parsing, release-only rows, the CSV contract | §5 |
| `app_flow_test`: a confident suggestion shows "Suggested on this phone" and no researcher line | D8 |
| `app_flow_test`: D8: long-pressing the code shows confidence, until turned off | D8 |
| `app_flow_test`: D8: researcher mode starts off; the researcher line's format | D8 |

CI runs the Dart tests on every push. The Python tests (`ml/tests`, `bench/tests`) run locally
with `ml/.venv/Scripts/python -m pytest ml/tests bench/tests`; CI does not run them yet.

## 8. What the numbers can claim

- **Categoriser:** generalisation to unseen phrasings of synthetic descriptions written from your
  knowledge. Chapter 3's "macro-F1 on a real held-out set ≥ 0.80" **cannot be measured** in this
  study. Report it as not measurable, beside the synthetic result, within the claim limits
  Chapter 3 already states.
- **Detector:** recall of four kinds of injected typing slip on synthetic ledgers. It says
  nothing about other kinds of unusual entry, such as fraud or a real but unusual day.
- **Efficiency** (latency, load time, size, memory) is fully measurable on synthetic inputs,
  because it depends on the model, not on whose words they are. It is the strongest result
  this phase can give.

## 9. Check it yourself

1. Build and install the real app (`flutter install --release` in `mobile/`), turn on airplane
   mode, and add an expense "bus fare to town". A category is suggested and the line says
   "Suggested on this phone".
2. Long-press the participant code. "Researcher mode on" appears, and the next suggestion shows
   its confidence, time in ms and model version. Close and reopen the app: researcher mode is off.
3. Enter five or more transport expenses of about K15, then one of K1,500. The "Is this right?
   Usually about K15.00" check appears.
4. Rename `assets/models/detector.json`, rebuild, and confirm the app still records entries with
   nothing flagged. Then restore it.
