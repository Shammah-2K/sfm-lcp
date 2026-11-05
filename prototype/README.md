# SFM-LCP prototype — FR1–FR3, fully offline

A throwaway Android build for the 13 October 2026 supervision. A market trader can, with no
network at all:

- **FR1** record a sale: amount, optional description, cash or mobile money;
- **FR2** record an expense with a short description;
- **FR3** get a category suggested on the phone and confirm or correct it;
- **FR8** do all of the above offline (the app contains no network code; the release manifest
  requests no INTERNET permission);
- **FR11** identify themselves with a participant code on first launch.

Saves go into the dissertation's on-device schema (`app/lib/data/schema.sql`, identical to
Chapter 3's `schema.sql`). The schema's triggers queue every save in the `sync_record` outbox,
which the cloud badge on Home counts.

## Layout

```
ml/   make_corpus.py -> data/corpus.csv ; train.py -> out/ (model, parity cases, metrics)
app/  Flutter app (package sfm_lcp_prototype)
      lib/ml/categoriser.dart     pure-Dart TF-IDF + logistic regression
      lib/data/schema.drift       Drift schema built from schema.sql
      lib/data/ledger_repository.dart, session.dart
      lib/theme.dart              every colour, size and text style
DECISIONS.md                      choices made where BUILD_PROTOTYPE.md was silent
```

## Regenerate the corpus and model

```bash
cd prototype/ml
python -m venv .venv
.venv/Scripts/python -m pip install -r requirements.txt   # .venv/bin/python on Linux/macOS
.venv/Scripts/python make_corpus.py
.venv/Scripts/python train.py
```

`make_corpus.py` is deterministic (seed 42): rerunning it reproduces `data/corpus.csv` byte for
byte. `train.py` checks that its reference `char_wb` analyzer matches scikit-learn on every corpus
row and parity case, then writes `out/metrics.txt` and copies the model to
`app/assets/models/` and the parity cases to `app/test/fixtures/`.

## Run the tests

```bash
cd prototype/app
flutter test
```

| Test | What it proves |
|---|---|
| `categoriser_parity_test.dart` | Dart probabilities equal scikit-learn `predict_proba` within 1e-6 on 300 cases |
| `amount_parser_test.dart` | Typed amounts become integer ngwee; zero, negative, >2 decimals and >K1,000,000 are rejected |
| `ledger_repository_test.dart` | Prediction fields and one pending outbox row per save; blank expense, DELETE and wrong-kind category rejected by the schema |
| `entry_screen_test.dart` | Save stays disabled until amount, description and category are valid; no overflow at 1.3x text |

After changing `schema.drift`, regenerate Drift code with `dart run build_runner build`.

## Build and install the release APK

```bash
cd prototype/app
flutter build apk --release --split-per-abi
adb install build/app/outputs/flutter-apk/app-arm64-v8a-release.apk
```

Use `app-armeabi-v7a-release.apk` for older 32-bit phones. The release build is signed with the
debug key, which is enough for `adb install` and not for distribution.

To inspect saved entries, install a **debug** build (`run-as` refuses release builds), copy the
database off the device and query it with Python, since most phones and emulator images have no
`sqlite3` binary:

```bash
flutter build apk --debug
adb install -r build/app/outputs/flutter-apk/app-debug.apk
adb exec-out run-as zm.ac.zcas.sfm_lcp_prototype cat app_flutter/sfm_lcp.sqlite > sfm_lcp.sqlite
python -c "import sqlite3; [print(r) for r in sqlite3.connect('sfm_lcp.sqlite').execute('SELECT entry_type, description, predicted_category, category_confidence, final_category, model_version FROM ledger_entry ORDER BY created_at DESC')]"
```

`ledger_repository_test.dart` checks the same fields against the real schema on every test run.

## Measured results

Measured on 12 October 2026 (Windows 11, Flutter 3.41.5, scikit-learn 1.9.1).

| Measure | Result |
|---|---|
| Corpus | 2,870 rows from 63 templates, 11 categories |
| Macro-F1 on held-out templates (13 test templates, 524 rows) | 0.4063 — see `ml/out/metrics.txt` for per-class F1 |
| Dart vs scikit-learn parity (300 cases, 11 classes) | passes; largest absolute difference 5.6e-16; top class agrees on 300/300 |
| Model JSON (`categoriser_model.json`) | 965,956 bytes, 3,705 features |
| Release APK, arm64-v8a | 19,409,436 bytes |
| Release APK, armeabi-v7a | 16,851,300 bytes |
| Release APK, x86_64 | 20,746,480 bytes |
| `flutter test` | 42 tests pass |

The macro-F1 is low by design of the split: each held-out template is a phrasing the model has
never seen, and categories whose test template shares no wording with their training templates
(food, other_expense, other_income, rent_levy and sales_goods in this split) score zero. It is reported as measured, not
tuned.

End-to-end check: the x86_64 release APK was installed on an Android emulator (API 36.1) in
airplane mode; a participant code, an expense ("bus fare to Matero", K25, suggested Transport)
and a sale (K50, no description, mobile money) were recorded and listed, and the outbox badge
counted 3. Suggestion timings shown in the app on the emulator are PC timings and say nothing
about a 2–4 GB phone; the physical-phone run is still to be done.

## This is a throwaway build

Everything in `prototype/` was written by an AI assistant (Claude Code) under
`BUILD_PROTOTYPE.md` to show the FR1–FR3 flow working end to end on the real schema. It is not
the dissertation's implementation and none of it is to be copied into `mobile/`. The corpus is
template-generated and exists only to give the prototype a working model; it must not be used in
the dissertation's evaluation, and the macro-F1 above says nothing about real MSME descriptions.
