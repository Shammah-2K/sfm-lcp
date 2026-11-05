# SFM-LCP: project status and context for Claude Cowork

Prepared 5 November 2026 by Claude Code for Shammah K. Kausa (ZCAS University, final-year
project). Final supervision: **10 November 2026**. Every number in this document was read from a
file in the repository or from a run that was actually performed; where something was not
measured, the document says so.

---

## 0. How to use this document (read first)

You are picking up a final-year project mid-flight. Before doing anything:

1. **Integrity rules (from the repository's `CLAUDE.md` working agreement).**
   - Never invent benchmark numbers, model accuracy figures or test results. Quote only what a
     script printed or a file records.
   - The machine-learning *results and their write-up* belong to Shammah. Claude may build
     tooling and explain results; Shammah runs training, chooses parameters (such as the
     confidence cutoff) and writes the evaluation.
   - Never commit raw participant data (`ml/data/raw/` is git-ignored and CI checks for it).
   - Every piece of AI-assisted work must be recorded in Shammah's AI assistance log.
2. **Where things are.** Repository: `C:\Users\shamm\Coding_Projects\Projects\FYP\sfm-lcp`
   (GitHub `Shammah-2K/sfm-lcp`, a **public** repository). Dissertation chapters:
   `C:\Users\shamm\OneDrive\Documents\FYP` (Chapter 3 in `Chapter3_Overleaf\chapter3.tex`, the
   database schema in `Chapter3_Overleaf\db\schema.sql`).
3. **Each phase has a review guide** in `docs/review/` explaining what was built, why, and how
   to check it. Read those before changing code in that area.

---

## 1. The project in one paragraph

SFM-LCP is an **offline-first
Android bookkeeping app for Lusaka micro, small and medium enterprises and market traders**,
built in Flutter. A trader records sales and expenses with a large keypad, gets an **on-device
category suggestion** for each description (FR3), is asked **"Is this right?"** when an amount
looks unusual (FR4), sees daily and weekly totals, keeps stock, and works fully without network.
When a connection returns, records **sync to a Supabase study server** (FR9), where the
researcher reads them on a **read-only web dashboard** (FR10). The research question is whether
lightweight on-device machine learning is feasible and useful on low-end Android phones (2–4 GB
RAM), judged against thresholds fixed in advance in Chapter 3.

---

## 2. What exists today: the applications

| Application | What it is | Status | Where |
|---|---|---|---|
| **Study app** ("SFM-LCP", `zm.ac.zcas.sfm_lcp`) | The real app participants use | Built, installed on Shammah's Galaxy S24+, syncing to the live Supabase project as participant **LSK1** | `mobile/` (entry `lib/main.dart`) |
| **Demo app** ("SFM-LCP Demo", `zm.ac.zcas.sfm_lcp.demo`) | The same app with three weeks of sample records for demonstrations; **never syncs** | Built and installed beside the study app on the S24+ (needs a one-off "Clear data", section 2.3) | `mobile/lib/demo/` |
| **Benchmark app** | A separate release entry point that measures the two models on a phone | Run on the S24+ only (high-end reference) | `mobile/lib/bench/`, `bench/` |
| **Study server** | Supabase project: tables, security, four functions | Live; migrations applied; anonymous sign-ins enabled; phone LSK1 synced | `backend/supabase/` |
| **Research dashboard** | One static web page for the researcher | Built and tested with sample data; **not yet confirmed against live data** (section 2.5) | `dashboard/` |
| **ML pipeline** | Python generators, training, evaluation, export | Models trained on Shammah's reviewed templates and committed | `ml/` |
| **Prototype** (October) | The throwaway first build (FR1–FR3) | Superseded; kept on branch `prototype/fr1-3` (merged to `main` as PR #1) | branch only |

### 2.1 Study app: features by requirement (Chapter 3)

| Req. | Requirement (priority) | Status |
|---|---|---|
| FR1 | Record a sale (Must) | Done: by amount or from products, cash or mobile money |
| FR2 | Record an expense with a description (Must) | Done; a stock purchase can list products bought, amount defaults to their total and can be overwritten |
| FR3 | On-device category suggestion, confirmed or corrected (Must) | Done: TF-IDF + logistic regression in pure Dart (`lr-v2`), preselects at confidence ≥ 0.7 |
| FR4 | Flag an unusual entry (Should) | Done: Isolation Forest in pure Dart (`iforest-v1`), "Is this right?" with "Usually about K…" |
| FR5 | Daily and weekly totals (Must) | Done (Lusaka days, Monday–Sunday weeks) |
| FR6 | Quick sale from a product list, reduces stock (Should) | Done |
| FR7 | Stock levels and low-stock warning (Should) | Done; plus edit product and "Stop selling" (hidden, never deleted) |
| FR8 | FR1–FR7 with no network (Must) | Done by design (all data local); see limitation L9 |
| FR9 | Sync when a connection returns (Should) | Done: outbox, sync worker, scheduler; **foreground only** (decision, section 4) |
| FR10 | Read-only web dashboard (Could) | Done for the researcher (section 2.5) |
| FR11 | Participant code (Must) | Done: consent, code, business type; code checked against the study list when online |
| FR12 | Reverse a mistaken entry; never edit or delete (Should) | Done: cancellation posts an exact reversal |

Also built: an in-app consent screen and "Stop taking part" (withdrawal asks the server to delete
the participant's copy), a one-time first-use hint, a sync badge and account sheet ("Sync now",
explanations when the code is refused or the server is unreachable), and **researcher mode**
(long-press the participant code: shows confidence %, prediction time and model version under
each suggestion; traders otherwise see "Suggested on this phone" without a percentage).

### 2.2 Architecture in brief

- **Flutter 3.41.5 / Dart 3.11.3**, Drift (SQLite) 2.34.x. The database is **Chapter 3's
  `schema.sql` included verbatim** (`mobile/lib/data/schema.drift`), plus one local table
  `app_state` for settings that is never synced.
- **Ledger rules live in the schema:** append-only ledger (corrections are reversal rows with a
  negative amount), integer ngwee for money, stock and totals derived through views, and an
  outbox (`sync_record`) filled by triggers in the same transaction as every change.
- **Ports architecture:** the UI depends only on interfaces in `mobile/lib/app/ports.dart`;
  `app_ports.dart` wires the real implementations. The models sit behind `CategoryPort` and
  `AnomalyDetector`, so either can be replaced without touching the ledger or UI.
- **Sync:** each install signs in anonymously to Supabase and claims its participant code once;
  the worker sends the current state of each changed record; the server applies each batch in
  one transaction and is idempotent on the phone's UUIDs.
- **Models are pure Dart**, reproducing scikit-learn exactly from exported JSON (no ML runtime in
  the app).

### 2.3 Demo app

- Seeds trader **DEMO01** (a Soweto market stall) on first launch, through the real repositories
  and models: 21 days of sales and expenses, stock purchases, Kapenta out of stock, cooking oil
  low, one cancelled entry, and today's **K250 taxi** (transport is usually about K25) waiting
  for "Is this right?". Today's entries are always placed before the moment it is opened.
- Separate package and database file; its entry point builds **no sync scheduler**, so sample
  data cannot reach the study server. The badge shows about 203 records "waiting", which is
  accurate (they never leave the phone).
- Build: `flutter build apk --release -t lib/demo/demo_main.dart -P sfmDemo=true` in `mobile/`.
  **Reset before each demo:** Settings → Apps → SFM-LCP Demo → Storage → Clear data.
- **Pending:** the first demo build placed some of today's entries after "now"; the fix is
  installed, but Shammah must clear the demo app's data once for it to reseed.

### 2.4 The Galaxy S24+ benchmark (high-end reference only)

The phone available is a Samsung Galaxy S24+ (SM-S926B, about 11 GB RAM, Android API 36). Chapter
3's performance criteria (NFR1, NFR2, NFR7) are about **2–4 GB phones**, so these figures are a
**high-end upper bound, not evidence for the thresholds**. Three cold runs of commit `7b6d774`,
release build, 100 warm-up then 1,000 timed calls each (`docs/bench/summary.md`, medians over
runs):

| Model | p50 | p95 | Max | First call | Load | Model file | RSS change on load |
|---|---|---|---|---|---|---|---|
| Categoriser `lr-v2` | 31 µs | 58 µs | 511 µs | 68 µs | 49.0 ms | 1,514 KB | 8.4 MB |
| Detector `iforest-v1` | 37 µs | 234 µs | 1,074 µs | 380 µs | 4.0 ms | 215 KB | 0.4 MB |

Whole-app memory (Android `dumpsys` TOTAL PSS) was about 299 MB with the screen on. That is the
whole Flutter app, **not** the models' increase, so it should not be compared with NFR2's "peak RAM
increase ≤ 50 MB"; the RSS change on load is the closer figure but is noisy (garbage collection).
An earlier batch was **discarded unrecorded** because the phone suspended the app mid-run (one
"call" took 178 s); the rerun was taken after confirming Android's *Stay awake* was on.

### 2.5 Study server and dashboard

- Supabase project URL and publishable key are in `mobile/supabase.json` and
  `dashboard/config.js`, both **git-ignored** (the repository is public). The `service_role` key
  must never be used in the app or repository.
- Participant codes LSK01–LSK20 seeded, plus **LSK1** (Shammah's phone, set up before the list
  existed).
- Verified live (29 Oct): an anonymous caller reads no rows and is refused every function except
  `check_code`; the phone signed in, claimed LSK1 and sent its 11 waiting records.
- Dashboard: researcher email sign-in (account listed in `public.researcher`), overview of every
  code, per-participant ledger, daily chart, categories and stock. Checked in a browser with
  sample data injected in the page only. **Not yet confirmed against live data**: Shammah's
  sign-in did not persist; he needs to sign in once on the clean page (served with
  `python -m http.server 8765 --directory dashboard`).

---

## 3. Timeline and branches

All work after the prototype is **local and unpushed** (25 commits). The branches form one line:
`main` (pushed, has the prototype) → `feature/app-ui` → `feature/data-layer` → `feature/ml` →
`feature/demo` (current, contains everything). Merging `feature/demo` into `main` through a pull
request brings everything across.

| Date | Phase | Commits |
|---|---|---|
| 12 Oct | Prototype FR1–FR3 (throwaway), merged as PR #1 | `e5397e9` |
| 25 Oct | Full UI from the design brief; working agreement and decisions | `ccb8644`, `42a5d35` |
| 25 Oct | Phase 1: CI, Drift database from Chapter 3's schema, schema tests | `d7172fc`, `1146166` |
| 25 Oct | Phase 2: ledger, totals, stock, session on the real database; sync badge fix | `1db3a87`, `cbe9390` |
| 25 Oct | Phase 3: consent, business type, first-use hint, stop taking part; font tried and reverted to Roboto | `42d7970`, `d315a10`, `bdbe721` |
| 27 Oct | Phase 4: products bought on a stock purchase; Phase 4b: edit product, Stop selling | `2596c7f`, `f0a9900` |
| 27–29 Oct | Phase 5: Supabase sync, SQL tests, refused-server message, research dashboard | `b71d206`, `0bf70a9`, `366d005`, `d50495e`, `b23d113` |
| 2–4 Nov | Phase 6: synthetic data, categoriser, detector, benchmark harness, researcher mode, trained models | `c0c3e64`, `d8b145a`, `8e8eb23`, `4bb144c`, `b4483af`, `027a5f4`, `7b6d774` |
| 5 Nov | S24+ benchmark; demo app | `60c020e`, `19a7c11` |

Uncommitted and harmless: `docs/screens/s09–s11*.png` (re-renders that differ only by today's
date), `ml/requirements.txt` and `ml/Untitled.ipynb` (Shammah's Jupyter set-up), and leftover
build folders under `prototype/`.

---

## 4. Strategic decisions that moved the project forward

| Date | Decision | Why it helped |
|---|---|---|
| 25 Oct | **Build the full UI first, behind interfaces (ports), with sample data** | Screens could be reviewed and tested before any logic; logic was then dropped in with no UI change |
| 25 Oct | **D1: Claude writes the app logic; Shammah reviews** (each phase on its own branch, small commits, a review guide, a named test per rule). ML stays Shammah's | Removed the bottleneck while keeping the work reviewable and attributable |
| 25 Oct | **Use Chapter 3's `schema.sql` verbatim** in the app | The dissertation's design and the running app cannot drift apart; 14 schema tests check its rules |
| 25 Oct | D2 expense flow records products bought; D3 in-app consent; D4 English only; D5 Supabase backend; D6 per-install token; D7 exact amounts in app and sync, rounded only in publications; D8 confidence % only in researcher mode; D9 cut the dashboard first, then the backend, if time ran out | Settled scope early; D5 (managed backend) saved days |
| 25 Oct | Reverted the trial font to Roboto | Smaller change surface; no loss of legibility |
| 27 Oct | **D6 details**: anonymous sign-in per install; one install per code; code checked at onboarding when online; withdrawal deletes server data; codes LSK01–LSK20 | No passwords for low-literacy users; codes cannot be hijacked by a second phone |
| 27 Oct | **Phase 4b**: edit product and "Stop selling" (hide, never delete) | Closed a gap against the design brief (S13) and UC9 |
| 27 Oct | **No user-defined categories** | The categoriser can only predict trained labels; the evaluation and cross-participant totals need the fixed codebook |
| 27 Oct | **Test the server SQL in real PostgreSQL (Docker)** | Found a real security gap before going live (section 5.2) |
| 29 Oct | **Sync runs in the foreground only** (no WorkManager background job) | Avoided a native plugin and a second database connection in a background isolate close to the deadline; traders open the app often |
| 29 Oct | **Dashboard for the researcher; UC12's actor changed** from "business owner" | Traders have no web sign-in; codes are not secrets |
| 2 Nov | **Synthetic training data** (supervisor approved verbally; no seed data collected) | Unblocked the ML phase; claims are limited accordingly (section 7) |
| 2 Nov | **ML split: Claude builds the engineering; Shammah reviews templates, trains, chooses the cutoff, reports** | Keeps the research findings Shammah's |
| 2 Nov | **Split evaluation by template (categoriser) and by trader (detector)** | Prevents leakage; scores measure generalisation, not memorisation |
| 2 Nov | **Reuse the prototype's proven Dart scorer and parity method** | Exact equality with scikit-learn was already demonstrated |
| 4 Nov | Templates accepted **unchanged** after review; cutoff **0.7** chosen by Shammah | Recorded so the write-up states it |
| 5 Nov | **S24+ used as a labelled high-end reference** until 2–4 GB phones are available | Progress without overstating evidence |
| 5 Nov | **Separate demo app that never syncs** | Demonstrable app without contaminating study data |

---

## 5. Testing

### 5.1 Totals (all passing on 5 Nov 2026)

| Suite | Count | Runs where |
|---|---|---|
| Flutter/Dart app tests (`mobile/test/`) | **178** | `flutter test` in `mobile/` |
| Python checks (`ml/tests/`, `bench/tests/`) | **23** | `ml/.venv/Scripts/python -m pytest ml/tests bench/tests` |
| SQL checks in PostgreSQL 15 (`backend/supabase/tests/`) | **54** | `bash backend/supabase/tests/run.sh` (needs Docker) |
| Screen renders (golden images) | 17 render tests → `docs/screens/` | `flutter test --update-goldens tool/screens` |
| CI (`.github/workflows/mobile.yml`) | no-raw-data check, format, code generation, analyze, test | **Has never run on Phases 1–6**: those branches were never pushed (limitation L10) |

### 5.2 Unit and component tests per significant code block

| Code block | Test file (count) | What is checked |
|---|---|---|
| Database schema (Chapter 3) | `data/schema_test.dart` (14) | Append-only ledger, reversal must match original, category kind matches entry type, expense needs a description, outbox rows written by triggers, views |
| Database upgrade | `data/migration_test.dart` (1) | Version 1 → 2 adds `app_state` without losing data |
| Ledger, totals, stock, session | `data/repositories_test.dart` (36) | Recording, cancellation by reversal, category change, unusual-entry answers, day/week totals in Lusaka time, stock derivation, onboarding order |
| Stock purchase (FR7) | `data/purchase_test.dart` (9) | Stock rises, cost kept per line, amount may differ, bad lines refused, cancel refused once stock sold |
| Edit product / Stop selling | `data/stop_selling_test.dart` (8) | Hidden not deleted, cannot sell or buy, duplicate names, bring back with count, sent with sync |
| Sync badge count | `data/sync_count_test.dart` (5) | Counts records a user recognises, not outbox rows; live updates |
| Money and date formatting, keypad | `format_test.dart` (23) | Integer ngwee parsing, kwacha formatting, Lusaka dates |
| Sync worker | `sync/sync_worker_test.dart` (21) | Sends all, signs in and claims once, idle uses no network, latest state wins, offline, lost reply, killed mid-run, token refresh, batch size 1, unknown/taken code, withdrawal (sent, before any sync, offline then retried), failure messages |
| Server contract | `sync/server_contract_test.dart` (3) | The SQL reads every column the phone sends; server codebook equals app codebook; grants and RLS present |
| Categoriser parity (NFR8) | `domain/categoriser_parity_test.dart` (5) | Dart equals scikit-learn within 1e-6 on 300 cases, top class agrees on all; suggestions stay within sale/expense |
| Detector parity (NFR8) | `domain/detector_parity_test.dart` (5) | Features and scores equal Python within 1e-12; an extra zero is flagged; too little history gives no opinion |
| Benchmark harness | `bench/benchmark_test.dart` (7) + `bench/tests/test_run_bench.py` (9) | Nearest-rank percentiles, inputs, a full run on the PC; logcat and dumpsys parsing; CSV rules (refuses non-release rows) |
| Demo seed | `demo/demo_seed_test.dart` (10) | DEMO01; seeding twice is a no-op; every one of 21 days has sales and expenses; today's taxi is the check; nothing after "now" (including just after midnight); one out, one low; no server set-up |
| Corpus generator | `ml/tests/test_make_corpus.py` (8) | Byte-identical reruns, every codebook category with the right kind, no unfilled slots, no duplicates per template, draft marking, typo rules |
| Ledger generator and features | `ml/tests/test_detector_data.py` (6) | Reproducible, labelled anomalies at about 2%, kinds correct, minimum history, features measure distance from usual |
| Server functions (SQL) | `sync_functions_test.sql` (37 checks) | Code check and claim, push stores once and resends nothing (NFR4 server half), last-writer-wins never changes an amount, all-or-nothing refusals, anon and app permissions, withdrawal deletes one phone only, `release_code` |
| Dashboard SQL | `dashboard_test.sql` (17 checks) | Only researchers read; views keep RLS (`security_invoker`); read-only; numbers net of cancellations, by Lusaka day, stock as on the phone |

### 5.3 Integration and end-to-end tests

| Test | Type | Result |
|---|---|---|
| `app_flow_test.dart` (17) | Widget flows on sample data, plus **no layout overflow at 360×640 and 1.3× text** on every screen | Pass |
| `onboarding_test.dart` (4), `purchase_flow_test.dart` (2), `stop_selling_flow_test.dart` (3) | Full screen flows on the **real database** | Pass |
| `sync/sync_ui_test.dart` (4) | Onboarding code check, Sync now, blocked code and refusing server explained, on the real database with an in-memory server | Pass |
| **NFR4 harness** `sync/nfr4_harness_test.dart` | 50 randomised trials of real app use with 30% of server calls failing (no network, lost reply after the server applied it, expired token) and simulated app kills; then the server copy is compared record by record with the phone | Last run: 50 trials, 2,049 records, 695 sync runs, 1,509 server calls; faults injected 136 no network, 141 lost replies, 131 expired tokens; 190 simulated kills; **0 trials with lost, extra or stale records**. Mutation check: deliberately breaking the worker made 43 of 50 trials fail, so the harness detects real faults |
| SQL in PostgreSQL 15 (Docker) | Migrations, seed, then 54 checks with a stand-in for Supabase's auth and default grants | All pass |
| Live Supabase checks (29 Oct) | Anonymous REST calls to tables and functions; the phone's first real sync | Lock-down holds; LSK1 claimed; 11 records sent |
| Dashboard in a browser | Overview, participant view, chart tooltip, table toggle, dark mode, phone width, participant text containing HTML shown as text | Pass with injected sample data; live data pending |
| On-device benchmark (S24+) | Release build, 3 cold runs | Section 2.4 |
| Demo app on device | Installed beside the study app, seeded on launch | Works; screenshot checked |
| Manual phone checks | Each phase installed and opened on the S24+ | Done per phase |

### 5.4 Problems that tests or checks found, and what was done

| Found by | Problem | Resolution |
|---|---|---|
| Drift code generation | A comment ending in a colon broke the SQL parser; `key` is reserved | Removed the colon; renamed the column `name` |
| Schema test | Reversing an expense violated "an expense needs a description" | Reversals copy the original's description |
| Widget tests | A stream listened to twice in a lazy list; several layout overflows at 1.3× text | Subscribe once in state; Flexible/FittedBox layouts |
| Phone check | The sync badge counted outbox rows (a 3-product sale counted 4) | Counts distinct records a user recognises |
| Migration test | A phone set up before the consent screen would fail onboarding | Consent-only path for existing participants |
| **SQL test in PostgreSQL** | Supabase grants new functions to `anon` directly, so anonymous callers could reach `sync_push`, `claim_code`, `withdraw` (they refused, but the lock-down was not as designed) | Revoked from all three roles; test added |
| SQL test | A Supabase view would bypass row-level security | Views made `security_invoker`; test added |
| First live sync | Nothing synced, silently: anonymous sign-ins were off in Supabase | Setting enabled; app now says "Can't reach the study server" when the server refuses |
| NFR4 harness | Cut off by the default 30 s test timeout on a loaded machine (not a failure) | Five-minute timeout |
| Benchmark | One detector "call" of 178 s and +100 MB memory: the phone suspended the app | Batch discarded unrecorded; rerun with Stay awake confirmed |
| Build | A background reinstall raced an Android config edit and installed the benchmark APK as the study app | Rebuilt cleanly and reinstalled; builds now delete the old APK first |
| Demo tests | Old flagged entry shown instead of today's taxi; products running out | Seed answers past flags as a trader would; stock floor for the "low" product |
| Phone screenshot | Demo entries for today timed after "now" | Today's entries placed before the moment of opening; midnight test added |
| Prototype evaluation | With about 6 templates per category, whole categories scored zero on held-out templates (macro-F1 0.4063) | Production corpus uses 18 templates per category |

---

## 6. The models, and what they were (and were not) compared against

### 6.1 Categoriser (FR3)

- **Data:** synthetic. 198 templates (18 per category for the 11 codebook categories) filled
  from local word lists (Lusaka places, goods, networks, workers, amounts) with seeded noise:
  typos (30%), case changes (10%), an amount typed into the description (10%). 11,124 rows,
  seed 42, deterministic. Templates were drafted with AI assistance and **accepted unchanged**
  by Shammah on review.
- **Model:** TF-IDF over character n-grams (scikit-learn `char_wb`, 2–4, sublinear tf, 6,000
  features) + multinomial logistic regression (C = 4.0). Hyperparameters were fixed from the
  prototype specification, **not tuned**.
- **Evaluation:** 20% of templates held out (40 templates, 2,262 rows); the shipped model is then
  refitted on all templates.

| Measure (held-out templates, synthetic) | Value |
|---|---|
| Keyword baseline, macro-F1, all classes | **0.3776** |
| TF-IDF + LR, macro-F1, all classes | **0.5028** |
| TF-IDF + LR, macro-F1, within sale/expense (what the app does) | **0.5828** |
| At cutoff 0.7 (chosen): share of suggestions preselected / accuracy of those | 0.5212 / 0.7379 |
| Model size / Dart–Python parity | 1.55 MB / within 1e-6 on 300 cases |

Weak classes (F1): transport 0.0632 (mostly predicted as stock), other_expense 0.0136,
sales_goods 0.3468 (precision 0.2098: a "sink" class many items fall into), wages 0.3251, stock
0.3186. Strong: utilities 0.9688, food 0.8168, rent_levy 0.7712.

### 6.2 Anomaly detector (FR4)

- **Data:** synthetic ledgers, 80 traders × 90 days (39,906 entries) with about 2% injected typing
  slips (×10, ×100, ÷10, ÷100; 789 in total). Amount scales and frequencies are assumptions,
  accepted unchanged.
- **Features:** the log ratio of the amount to the trader's usual (median) amount in that category
  over the last 60 days, and the same in units of their spread (MAD); no opinion with fewer than 5
  earlier entries.
- **Model:** Isolation Forest (100 trees, 256 samples), fitted unsupervised on 60 traders; the
  flagging threshold (0.6868) chosen on those traders by best F1, which uses labels; reported on 20
  held-out traders.

| Measure (held-out traders, synthetic) | At chosen threshold | At the classic 0.5 |
|---|---|---|
| Precision / recall / F1 | 0.9183 / 0.9455 / 0.9317 | 0.2343 / 1.0000 / 0.3797 |
| Normal entries wrongly flagged | 0.19% | 7.45% |
| Recall by slip: ×10 / ×100 / ÷10 / ÷100 | 0.8701 / 1.0 / 0.9825 / 1.0 | all 1.0 |

### 6.3 What the models were compared against: the honest answer

**Categoriser: keyword baseline and five alternatives (alternatives added 5 Nov).** The keyword
baseline is learned from the training templates (words seen in only one category vote for it),
so it is a fair floor. `ml/train_categoriser.py` now also tunes each alternative by grouped
5-fold cross-validation **on the training templates only**, then scores it once on the same
held-out templates. Output of the run on 5 Nov (`ml/out/categoriser_metrics.txt`):

| Model | CV macro-F1 (train templates) | Test macro-F1 | Within kind | Preselected at 0.7 | Accuracy then |
|---|---|---|---|---|---|
| Keyword baseline | – | 0.3776 | – | – | – |
| **Char TF-IDF + LR, C=4 (shipped, lr-v2)** | 0.5613 | 0.5028 | 0.5828 | 0.5212 | 0.7379 |
| Char TF-IDF + LR, tuned (2–5 grams, C=4) | 0.5720 | 0.4940 | 0.5850 | 0.5363 | 0.7279 |
| Word TF-IDF + LR (C=16) | 0.5368 | 0.4329 | 0.4841 | 0.6627 | 0.6611 |
| Char TF-IDF + linear SVM (C=1) | 0.5714 | 0.5303 | 0.5977 | – (no probabilities) | – |
| Char TF-IDF + Complement NB (α=1) | 0.5531 | 0.5349 | 0.6044 | 0.3382 | 0.8366 |
| Word counts + Multinomial NB (α=0.03) | 0.5116 | 0.4097 | 0.4646 | 0.7436 | 0.6861 |

**Reading it:** every character-level model lands between 0.49 and 0.54 on the held-out
templates, and the order on the test set differs from the order in cross-validation. The test
set is only 40 templates, so differences of a few points are within noise. **No alternative is
clearly better than the shipped model**; word-level models are clearly worse (they cannot
handle unseen spellings and typos). The ceiling is the synthetic data's template variety, not the
choice of classifier. The SVM gives no probabilities, which the confirm/correct interface needs,
so it would need calibration to be used. How to present this is Shammah's call.

- **Still not compared:** **fastText** and the **small language model** arm (both listed in
  Chapter 3's models table), and any comparison with a published model or dataset.
- **Against Chapter 3's own criterion:** "Macro-F1 (real held-out set) ≥ 0.80 and > keyword
  baseline". The "> keyword baseline" half is met on synthetic data. The 0.80 half **cannot be
  measured** without real data, and even the synthetic score (0.50) is well below it.

**Detector: simple-rule baselines (added 5 Nov, after this document was first written).**
The injected anomalies are **order-of-magnitude slips**: with the assumed day-to-day spread
(σ = 0.4 on the log scale), a ×10 slip sits about 2.3 log units, roughly 5–6 spreads, from usual.
`ml/train_detector.py` now scores five simple rules on the same held-out traders, entries, history
and split as the forest, with tuned cut-offs chosen on the training traders. Output of the run on
5 Nov (`ml/out/detector_metrics.txt`):

| Method (held-out traders) | Precision | Recall | F1 | Normal flagged |
|---|---|---|---|---|
| Isolation Forest (threshold 0.6868) | 0.9183 | 0.9455 | 0.9317 | 0.0019 |
| Ratio rule, fixed: > 5× or < ⅕ of the median | 0.9896 | 0.9455 | **0.9671** | 0.0002 |
| Ratio rule, tuned (4.25×) | 0.9561 | 0.9703 | 0.9631 | 0.0010 |
| Robust z, tuned (3.99) | 0.8488 | 0.8614 | 0.8550 | 0.0035 |
| Mean ± 3 SD on raw amounts, fixed | 0.4648 | 0.4901 | 0.4771 | 0.0129 |
| Mean ± SD on raw amounts, tuned (5.24) | 0.7778 | 0.4505 | 0.5705 | 0.0029 |

**On this synthetic data, the one-line ratio rule matches or beats the Isolation Forest**
(same recall, higher precision). The forest therefore shows **no added value over a simple
rule here**, which is expected since the slips are order-of-magnitude by construction. This
is a valid finding to report honestly; how to interpret it (keep the forest for the
less obvious anomalies real data might contain, or ship the rule) is Shammah's call. Classic
mean ± SD on raw amounts does badly: it almost never catches ÷10 or ÷100 slips, because a small
amount is few raw SDs from the mean. That supports the log-scale features.

**Performance: no comparison with another model either.** The benchmark measures the chosen
models against Chapter 3's absolute thresholds (p95 ≤ 100 ms, model ≤ 5 MB, RAM increase ≤ 50 MB,
load ≤ 1 s), and so far only on a high-end phone.

### 6.4 Advice: closing the comparison gap before 10 November

Low effort and high value, all on the existing splits, so no new data is needed:

1. **Detector baselines (most important). Done 5 Nov; results in section 6.3.** In `ml/train_detector.py`, evaluate on the same
   held-out traders: (a) the ratio rule above with the ratio chosen on training traders, and (b) a
   robust z-score rule (|z| above a threshold chosen on training traders). Report precision,
   recall and F1 next to the forest. If a rule matches the forest, say so: it is a valid finding
   (the simpler model suffices) and the app could ship either.
2. **Categoriser alternatives. Done 5 Nov; results in section 6.3.** In `ml/train_categoriser.py`, on the same template split:
   Multinomial/Complement Naive Bayes, linear SVM (with probability calibration if it is to drive
   preselection), word-level TF-IDF + LR, and two or three values of C and n-gram range, chosen
   by cross-validation on the training templates only, never on the test templates. Report a
   small table.
3. **A real-data check, even small.** The Zambian Financial Diaries 2015 (DataFirst, free
   account) contain real Zambian transaction descriptions. Shammah would download them (accepting
   the terms) and hand-label a few hundred against the codebook. That turns "not measurable" into
   a real, if small, test of the 0.80 criterion.
4. **Measure on 2–4 GB phones** (bench harness ready): this is NFR1/NFR2/NFR7's evidence.
5. **Report fastText and the SLM arm as not evaluated**, under Chapter 3's earned-scope rule,
   with the reason (time; no proven on-device runtime).

Every result must come from running the scripts; Shammah runs them and reports the numbers.

---

## 7. Limitations

| # | Limitation | Consequence for claims |
|---|---|---|
| L1 | **All training and evaluation data are synthetic** (templates and amount assumptions drafted with AI assistance and accepted unchanged) | Accuracy describes generalisation to unseen *templates*, not to real trader descriptions; Chapter 3's real-data F1 criterion is not measurable |
| L2 | Categoriser macro-F1 0.50 (0.58 within kind) on held-out templates, below 0.80 | The suggestion is often wrong on unseen phrasings; preselection at 0.7 applies to about half of entries, at about 74% accuracy (synthetic) |
| L3 | **Injected anomalies are easy by construction; a 5× ratio rule matches the forest on them** | Isolation Forest's added value is not shown on synthetic data (section 6.3) |
| L4 | Detector threshold chosen with labels | Not purely unsupervised; say "threshold calibrated on labelled synthetic data" |
| L5 | **Performance measured only on a high-end phone** | NFR1, NFR2, NFR7 not yet evidenced on 2–4 GB devices |
| L6 | App PSS is whole-app memory; RSS change is noisy | NFR2's "RAM increase" is measured indirectly |
| L7 | **Usability (NFR5, tasks T1–T4) not yet tested with participants** | No evidence yet that traders complete tasks without help |
| L8 | Sync runs only while the app is open (no background job) | Records wait until the app is next opened; FR9 met in a weaker form |
| L9 | Airplane-mode operation (NFR3) is by design but not formally tested on a device | Run and record the T1–T4 tasks in airplane mode |
| L10 | **CI has never run on Phases 1–6** (unpushed branches) | NFR8's "CI runs on every push" not yet evidenced; push and merge |
| L11 | English only (D4); no translation file yet | Nyanja/Bemba users not served |
| L12 | Fixed codebook; no user categories | By design for the ML and evaluation; may not fit every business |
| L13 | Anonymous session stored on the phone; clearing app data creates a new install that the code refuses until `release_code` | Small operational burden for the researcher |
| L14 | Dashboard confirmed only with sample data | Confirm with live data before showing it |
| L15 | Supabase region and data retention not yet cleared with the supervisor (decision F); synthetic-data approval only verbal | Get both in writing for the ethics section |
| L16 | Model per category is global; no per-trader adaptation; models are static (retraining needs a new app build) | No learning from user corrections yet |

---

## 8. Future work

**Before 10 November (in priority order):**
1. Detector baselines and categoriser alternatives are done (section 6.3); decide how to
   present their results.
2. Benchmark on the 2–4 GB phones (`ml/.venv/Scripts/python bench/run_bench.py`, then
   `plot_bench.py`), and measure APK size
   (`flutter build apk --release --analyze-size --target-platform android-arm64`).
3. Usability tasks T1–T4 with participants (NFR5), including in airplane mode (NFR3).
4. Push the branches, open a pull request into `main`, and let CI run (NFR8).
5. Confirm the dashboard with live data; clear the demo app's data once.
6. Chapter 3 updates: UC12 actor → researcher; dataset construction → synthetic, approved by
   the supervisor; foreground-only sync; the real-data criterion reported as not measurable; fill
   the `\writehere` for the sync backend (Supabase) in the alternatives table; D7 ethics wording
   (exact amounts, rounded only in publications).
7. AI assistance log entries for every phase.

**After the project (dissertation "future work"):**
- Real-data collection with consent, and evaluation on a real held-out set.
- Learning from corrections: use confirmed and corrected categories (already stored as
  `predicted_category` vs `final_category`) to retrain, or to adapt per trader on the device.
- fastText or a small language model on the device, if a runtime proves feasible.
- Background sync (WorkManager), with care for the single-writer database.
- Nyanja and Bemba (move all strings into a translation file).
- A trader-facing web view, which would need a proper sign-in.
- A credit-ready export (PDF/CSV the trader chooses to share, marked "not audited"; no credit
  score) for loans or other financial services, discussed and parked as an FR13 "Could".
- Levy collection and a municipal dashboard (out of scope in Chapter 3).
- Richer anomaly types (duplicates, wrong category, timing) and per-trader thresholds.

---

## 9. Items you may also need (added beyond the brief)

- **Open questions for Shammah:** written synthetic-data approval; data location and retention
  (decision F); whether to run the comparisons in section 6.4; which phones are the 2–4 GB test
  devices.
- **Commands cheat-sheet:**
  - App tests: `cd mobile && flutter test`
  - Python checks: `ml/.venv/Scripts/python -m pytest ml/tests bench/tests`
  - SQL checks: `bash backend/supabase/tests/run.sh` (Docker running)
  - Regenerate data and models: in `ml/`, `make_corpus.py`, `train_categoriser.py --cutoff 0.7`,
    `make_amounts.py`, `train_detector.py`; then `python bench/make_bench_texts.py` from the
    repository root and `flutter test` (the parity tests must pass)
  - Study app with sync: `flutter build apk --release --dart-define-from-file=supabase.json`
  - Demo app: `flutter build apk --release -t lib/demo/demo_main.dart -P sfmDemo=true`
  - Benchmark: `ml/.venv/Scripts/python bench/run_bench.py --note "…"`, then `bench/plot_bench.py`
- **Review guides:** `docs/review/phase-1-2.md`, `phase-3.md`, `phase-4.md`, `phase-4b.md`,
  `phase-5.md` (sync and dashboard), `phase-6.md` (models, parity, benchmark, researcher mode),
  `demo-app.md`. Plans: `docs/plans/next-phase-plan.md`. Design: `docs/design/ui-design-brief.md`.
- **Secrets:** none are in the repository. `mobile/supabase.json` and `dashboard/config.js` are
  git-ignored. Never paste the Supabase `service_role` key anywhere.
- **Devices:** Galaxy S24+ (SM-S926B, adb serial R5CXB2EL4GM) has the study app (LSK1) and the
  demo app. The 2–4 GB test phones are not yet available.
