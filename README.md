# SFM-LCP — SME Financial Management Platform

> An offline-first Android bookkeeping app for Lusaka market traders and MSMEs, with two on-device
> models: an expense/sale category suggester and an "is this amount right?" anomaly check.

![Platform](https://img.shields.io/badge/platform-Android-green)
![Stack](https://img.shields.io/badge/stack-Flutter%20%7C%20Drift%20%7C%20Supabase%20%7C%20scikit--learn-blue)

## About

SFM-LCP is the final-year project of Shammah King Kausa, BSc Computer Science, **ZCAS University,
Lusaka, Zambia** (2026/2027). Most market traders in Zambia's informal economy keep no written
records. The app lets a trader record sales and expenses in a few taps, see the day's and week's
totals, and keep track of stock, entirely on the phone and without network. For the study, it
sends a copy of the records to a server when there is network.

## What was built

| Part | Folder | What it does |
|---|---|---|
| **The app** | `mobile/` | Flutter app. Records sales (amount or products) and expenses (with products bought), suggests a category, asks "Is this right?" on unusual amounts, day and week totals, stock with low-stock flags, cancel by reversal (the ledger is append-only, money in integer ngwee). SQLite via Drift, schema from the dissertation's `schema.sql`. |
| **The models** | `ml/` | Training and evaluation on synthetic data: TF-IDF (char 2–4 grams) + logistic regression for categories, Isolation Forest for amounts, each compared with baselines and alternatives. Both run on the phone in pure Dart, checked against scikit-learn. |
| **The study server** | `backend/` | Supabase (Postgres) migration: anonymous sign-in per install, one-time participant codes, sync and withdrawal functions, row-level security. SQL tests run in Docker. |
| **The dashboard** | `dashboard/` | A static, read-only page for the researcher: participants, entries, sync and model use. |
| **The benchmark** | `bench/` | Measures model load time, prediction latency and memory on a real phone (release build). |
| **The demo app** | `mobile/lib/demo/` | The same app with three weeks of sample records, installed beside the real one; never syncs. |
| **The prototype** | `prototype/` | An earlier throwaway FR1–FR3 build. Not the implementation. |
| Screens | `docs/screens/` | Rendered images of every screen. |
| Design | `docs/design/` | The UI design brief the app follows. |
| Results | `ml/out/`, `docs/bench/` | Model metrics and benchmark results, as committed. |
| Phase guides | `docs/review/` | What each phase built and how it was tested. |

Not built: MTN Mobile Money integration, phone-number login, a Nyanja translation, and background
sync (sync runs while the app is open).

## Requirements

| Tool | Version used | For |
|---|---|---|
| Flutter / Dart | 3.41.5 / 3.11.3 | the app, its tests, the demo and bench builds |
| Android SDK + a phone or emulator | API 36 tested | running the app |
| Python | 3.14 | training, evaluation, benchmark scripts |
| Docker | any recent | the SQL tests only |
| A Supabase project | free tier | sync and the dashboard only; the app works offline without it |

## Reproduce

Commands are from the repository root unless a step says otherwise. On macOS or Linux, use
`.venv/bin/python` where these say `.venv/Scripts/python`.

### 1. The models

```bash
cd ml
python -m venv .venv
.venv/Scripts/python -m pip install -r requirements-pipeline.txt
.venv/Scripts/python -m pytest tests                  # pipeline checks
.venv/Scripts/python make_corpus.py                   # templates -> data/processed/corpus.csv
.venv/Scripts/python train_categoriser.py --cutoff 0.7
.venv/Scripts/python make_amounts.py                  # synthetic ledgers -> data/processed/amounts.csv
.venv/Scripts/python train_detector.py
```

Everything is seeded, so the corpus, the ledgers, the metrics in `ml/out/` and the exported models
come out the same. The training scripts copy the models into `mobile/assets/models/` and the
parity cases into `mobile/test/fixtures/`. Details, and what the numbers can and cannot claim,
are in [`ml/README.md`](ml/README.md).

**All training and test data are synthetic** (supervisor-approved). The results describe how
well the models handle phrasings and traders they did not see in training, not accuracy on real
trader records. No participant data is in this repository, and `ml/data/raw/` is never committed
(CI fails if it is).

### 2. The app

```bash
cd mobile
flutter pub get
dart run build_runner build      # generates the Drift code (*.g.dart, not committed)
flutter analyze
flutter test                     # unit, widget, database, sync and model-parity tests
flutter run                      # offline only, no study server
```

The parity tests (`test/domain/*_parity_test.dart`) check that the Dart models give the same
answers as scikit-learn on the cases exported in step 1. More in [`mobile/README.md`](mobile/README.md).

### 3. The study server (optional)

Follow [`backend/README.md`](backend/README.md): create a Supabase project, turn on anonymous
sign-ins, run the migrations and `seed_codes.sql`, then copy `mobile/supabase.example.json` to
`mobile/supabase.json` (git-ignored) and build with
`flutter run --release --dart-define-from-file=supabase.json`.

To test the SQL without Supabase (needs Docker): `bash backend/supabase/tests/run.sh`.

### 4. The dashboard (optional)

Follow [`dashboard/README.md`](dashboard/README.md): run the dashboard migration, add a researcher
account, copy `dashboard/config.example.js` to `dashboard/config.js` (git-ignored), then
`python -m http.server 8765 --directory dashboard`.

### 5. The on-device benchmark

With a phone connected over USB debugging:

```bash
ml/.venv/Scripts/python bench/run_bench.py --note "conditions of the run"
ml/.venv/Scripts/python -m pip install -r bench/requirements.txt
ml/.venv/Scripts/python bench/plot_bench.py      # results.csv -> docs/bench/
```

The bench build replaces the app on the phone. See [`bench/README.md`](bench/README.md) for
what is measured and how to reinstall the app afterwards. The committed results are from one
high-end phone (Galaxy S24+), a reference only. The study's targets are 2–4 GB phones.

### 6. The demo app

```bash
cd mobile
flutter build apk --release -t lib/demo/demo_main.dart -P sfmDemo=true
adb install -r build/app/outputs/flutter-apk/app-release.apk
```

It installs as "SFM-LCP Demo" (`zm.ac.zcas.sfm_lcp.demo`) beside the study app, with its own
database, and fills itself with three weeks of sample records on first launch. To start
afresh: Settings → Apps → SFM-LCP Demo → Storage → Clear data.

## Secrets

The repository is public. `mobile/supabase.json` and `dashboard/config.js` hold the project URL
and the publishable (anon) key, which are public by design. Both are git-ignored anyway. The
Supabase `service_role` / secret key must never be used in the app, the dashboard or this
repository.

## Author

**Shammah King Kausa**
BSc Computer Science, ZCAS University
Lusaka, Zambia

- GitHub: [Shammah-2K](https://github.com/Shammah-2K)
- LinkedIn: [shammah-kausa](https://www.linkedin.com/in/shammah-kausa-0a81042b2)
- Email: shammahk1usa [at] gmail [dot] com

## Acknowledgements

Supervised at ZCAS University, Department of Computer Science. Built with reference to the
Eighth National Development Plan and Zambia's National Financial Inclusion Strategy 2023–2027.
AI assistance (Claude Code) was used in building the software; it is declared in the
dissertation.

## License

MIT — see [LICENSE](./LICENSE) when added.
