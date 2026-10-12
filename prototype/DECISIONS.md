# DECISIONS.md

Choices made during the build that `BUILD_PROTOTYPE.md` does not specify, one per line.

- Android application id `zm.ac.zcas.sfm_lcp_prototype`; launcher label "SFM-LCP"; Android is the only platform generated.
- `prototype/app/.gitignore` re-includes `pubspec.lock`, because the repository root ignores `*.lock` and an application must pin its dependency versions.
- Analyzer runs with `strict-casts` and `strict-raw-types` on top of `flutter_lints`.
- Corpus `{qty}` expands to "<n> <unit> of" (e.g. "15 boxes of") so templates such as "bought {qty} {item}" read naturally.
- Corpus deduplication runs after generating 120 samples per template, so slot-free templates (e.g. "lunch") keep only their distinct typo/case variants (20–120 rows per template, 2,870 rows total).
- "Randomise case" picks one of ALL CAPS, Title Case or per-character random case; typos are skipped on strings shorter than 3 characters.
- The corpus-only notice lives in the `make_corpus.py` header, not in `corpus.csv`, so the CSV stays parseable by any reader.
- The template split also requires every category to appear in the training half, not just the test half.
- Parity cases: 200 sampled corpus rows, 80 new typo variants absent from the corpus (seed 7), and 20 hand-written edge cases.
- The model JSON keeps full float64 precision (about 0.97 MB) instead of rounding, so parity is not limited by export precision.
- `requirements.txt` pins the exact versions used (scikit-learn 1.9.1, numpy 2.5.4, Python 3.14.8).
- `prototype/.gitattributes` forces LF line endings so `corpus.csv` stays byte-identical to a fresh `make_corpus.py` run on Windows checkouts.
- The category codebook lives once in `lib/domain/categories.dart` and feeds both the database seed and the categoriser's income/expense restriction.
- The model JSON is parsed with `Isolate.run` at startup so the ~1 MB decode does not block the first frame.
- Drift is pinned to 2.34.x (drift_dev 2.34.0) because newer drift_dev needs `meta` ^1.18, which the installed Flutter 3.41.5 SDK pins to 1.17.0.
- `schema.drift` differs from `schema.sql` only in comments and the PRAGMA line: drift_dev 2.34 fails to parse a `CREATE TABLE` that follows a line comment ending in a colon ("-- Conventions:"), so that colon is dropped. Every table, index, trigger and view is accepted by drift_dev, so no statement runs through `customStatement`.
- Drift types the `TEXT PRIMARY KEY` columns as nullable (SQLite allows NULL there without NOT NULL); the schema is kept verbatim and the Dart code unwraps ids it has just generated.
- Drift's generated `Category` and `LedgerEntry` classes would clash with domain names, so the codebook class is `CategoryDef` and data-layer files import `database.dart` with `hide LedgerEntry`.
- `Session` returns a small `Participant` (business id + code) instead of Drift's `BusinessData`.
- Amount parsing accepts a trailing point ("25." = K25.00), a leading point (".5" = K0.50) and leading zeros, and rejects anything with more than seven whole-kwacha digits before converting.
- `recordSale` stores `sales_goods` when no final category is passed; it never promotes an unconfirmed suggestion to the final category.
- `watchRecent` breaks ties on equal `created_at` by `rowid`, so two saves in the same millisecond still list newest first.
