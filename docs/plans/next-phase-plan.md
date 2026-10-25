# SFM-LCP — plan for the logic and onboarding phases

Drafted 25 October 2026 for approval. Final supervision is **10 November 2026 (16 days)**.
Inputs: Chapter 3 (FR1–FR12, NFR1–NFR8, UC1–UC12, schema, sync design, ethics), the UI design
brief, and the UI now on branch `feature/app-ui`.

---

## 1. Where things stand

| Layer | State |
|---|---|
| UI (S01–S15) | Built, tested, rendered. Talks only to the interfaces in `mobile/lib/app/ports.dart` |
| Data on the phone | None. The app runs on fixed preview data |
| Database schema | Written and tested in Chapter 3 (`schema.sql`, 12 constraint tests) but not in `mobile/` yet |
| Sync, backend, dashboard | Not started (`backend/` is empty) |
| ML | Deferred to the last phases by your decision; seed corpus still to be collected |
| CI | Not set up. NFR8 says CI runs on every push |

## 2. What has to be implemented

### 2.1 Requirement by requirement

| Req. | Priority | What is missing | Notes |
|---|---|---|---|
| FR11 Participant code | Must | Save the `business` row; read it at start | Small |
| FR1 Record a sale | Must | Insert `ledger_entry` (amount, method, category) in one transaction | The trigger queues the outbox row |
| FR2 Record an expense | Must | Same, with a required description | The schema CHECK already enforces it |
| FR5 Day/week totals | Must | Day totals from `v_daily_summary` (Lusaka is UTC+2); a week query (Mon–Sun) on top; per-category totals | Today strip and Totals tab |
| FR8 Offline | Must | Nothing extra, as long as nothing above touches the network | Prove it with an airplane-mode test (NFR3) |
| FR12 Reverse an entry | Should | Insert the reversing entry; the list shows the original as cancelled and hides the reversal row | `trg_reversal_matches` checks the amount |
| FR3 Category suggestion | Must | **ML phase.** Until then `CategoryPort` returns nothing, so the user always picks a category | Store `predicted_category` as null until a model exists |
| FR4 Unusual entries | Should | **ML phase.** Until then nothing is flagged. "Usually about K…" must come from the detector's result | Needs the detector to return a typical amount, not just a flag |
| FR6 Quick sale | Should | Insert `entry_item` rows with the sale; the ledger computes the amount from lines × prices | The basket total moves from the UI into the ledger |
| FR7 Stock and low-stock | Should | Products, `v_stock_level`, `v_low_stock`, adjustments (opening, count, damage, other) | **Gap:** stock bought is never added (see decision D2) |
| FR9 Sync | Should | Outbox reader, batching, back-off, WorkManager job, and a backend that stores each UUID once | The algorithm is yours (CLAUDE.md) |
| FR10 Dashboard | Could | Read-only web view of synced records | First thing to cut if time runs short |
| NFR1/NFR2 | — | Benchmark harness on two low-end phones | ML phase |
| NFR4 | — | Interrupted-sync trials (N runs, no loss, no duplicates) | Needs a test harness |
| NFR7 | — | Confirm the minimum API level against the two test phones | |
| NFR8 | — | GitHub Actions: analyze, test, and the parity test once the model exists | |

### 2.2 Onboarding

What first launch has to cover, from Chapter 3's ethics section and the use cases:

1. **Welcome and consent.** A short plain-language screen confirming the participant agreed
   (the paper consent sheet is read by you in their language), with "I agree" or "Not now".
   Records only the time of consent. No names.
2. **Participant code** (exists, S01). Add: switch off keyboard suggestions, and add a "Wrong code?"
   path back.
3. **Type of business** (`business.business_type`, already in the schema): three or four icon
   choices (market stall, shop, service, other). Useful for the evaluation; one tap.
4. **Optional first-use hints.** One-line hints on Today the first time ("Tap Sale when money
   comes in"), dismissed on first use. They help T1–T4 succeed "without help" (NFR5) but are
   not a tutorial.
5. **Account sheet** (S15, extended): participant code, sync status and **"Stop taking part"**
   (withdrawal: stops sync and marks the participant withdrawn so server data can be deleted).
   Ledger data on the phone stays append-only.

Also part of this phase: the Atkinson Hyperlegible font (needs your OK to download), and moving
all text into a translation file so Nyanja or Bemba can be added later without touching screens.

## 3. Decisions

**Decided 25 Oct 2026:** D1 (b): Claude writes the logic and Shammah reviews it; ML stays Shammah's unless
he says otherwise before Phase 6. D2 (a) expense flow records products bought. D3 (a) in-app
consent. D4 English only, strings extracted. D5 Supabase. D6 per-install token with initial
authentication (assumed: Supabase anonymous sign-in per install, plus a participant code checked against a
researcher-issued list on first connection; confirmed at the start of Phase 5). D7, D8, D9 as
recommended.

The options as originally proposed:

| # | Decision | Options | Recommendation |
|---|---|---|---|
| D1 | **Who writes the logic** | (a) As CLAUDE.md says: Claude writes interfaces, tests that define "done", scaffolding and UI; you write the logic that makes those tests pass. (b) You authorise Claude to write some or all of the logic (as for the prototype), recorded in the AI assistance log | **(a), test-first.** It keeps the integrity line clear and the tests become Chapter 4 evidence. If time forces (b) for some parts, decide per part and record it |
| D2 | How stock goes up (FR7) | (a) An expense in "Stock purchase" can add products and quantities bought (`entry_item` on an expense, as the schema intends). (b) For v1, stock only goes up through "Adjust stock → Counted" | (b) for the deadline, (a) as future work; say so in Chapter 5 |
| D3 | Consent in the app | (a) A consent screen as in 2.2. (b) Paper consent only | (a). It is one screen and evidences the procedure |
| D4 | Languages for v1 | English only, or English plus Nyanja labels | English for v1, with strings extracted now |
| D5 | Backend stack and host | Node + TypeScript + Express + PostgreSQL on Railway (README), or a managed option such as Supabase (Postgres + REST) | Supabase is fastest given 16 days, and Chapter 3 only commits to "Sync API + PostgreSQL". Either works with the same sync contract |
| D6 | How a phone proves who it is when syncing | A per-install random token created at onboarding and registered with the participant code on first sync | Token per install. No passwords to type (low literacy) |
| D7 | "Rounded amounts" in the ethics text | Round amounts in synced copies, or sync exact amounts and round only in reports | Exact on the phone and in sync; round in anything published. Fix the ethics wording |
| D8 | Show the confidence % to traders | Show it, or show "Suggested" only and keep the % in a researcher mode | Researcher mode (long-press the code pill) |
| D9 | What to cut if time runs out | FR10 dashboard first, then the FR9 backend (keep the client outbox) | Agree the cut line now |

## 4. The phases

**Who:** under D1(b) Claude writes everything below except ML (Phase 6), and each phase ships with
a review guide in `docs/review/` that Shammah reads. The "Who" columns show the original D1(a) split
for reference. Every phase ends with: analyze clean, all tests green, a release APK run on a phone,
committed on its own branch.

### Phase 1 — Foundations (1–2 days)

| Task | Who |
|---|---|
| GitHub Actions: `flutter analyze`, `flutter test`, format check on every push (NFR8) | Claude |
| Drift database in `mobile/lib/data/` built from Chapter 3's `schema.sql`, unchanged; migration v1; foreign keys on; category seed | Claude (wiring the existing schema) |
| Composition root: build real ports in `main.dart`, keep preview ports for tests and screenshots | Claude |
| **Contract tests** for every port against an in-memory database, failing until implemented. They define "done" for phases 2–4 | Claude |
| Repository skeletons with signatures and docs, bodies left to fill | Claude |

**Done when** CI is green on GitHub, the app starts on a real database file, and the contract
tests run and fail for the right reason.

### Phase 2 — Ledger core (3–4 days): FR1, FR2, FR5, FR8, FR11, FR12

| Task | Who |
|---|---|
| `SessionPort`: business row, consent time, business type | Shammah |
| `LedgerPort`: record sale and expense in one transaction; today's entries (UTC+2 day); cancel by reversal; change category; hide reversal rows from lists | Shammah |
| `TotalsPort`: day from `v_daily_summary`, week (Mon–Sun), per-category totals | Shammah |
| `CategoryPort` and anomaly detector as "no model yet" stand-ins (return nothing) | Claude |
| Airplane-mode integration test on a device (NFR3) | Claude |

**Done when** the phase-1 contract tests pass, and T1 (by amount), T2 and T4 work on a phone in
airplane mode after a restart.

### Phase 3 — Onboarding and account (2 days)

| Task | Who |
|---|---|
| Consent, business type, first-use hints and "Stop taking part" screens; keyboard fix on the code field | Claude |
| Strings into a translation file; Atkinson Hyperlegible bundled (after your OK) | Claude |
| Saving consent, business type and withdrawal state | Shammah |

**Done when** a fresh install walks consent → code → business type → Today, and a reinstall
skips straight to Today once the participant exists.

### Phase 4 — Stock and quick sale (2 days): FR6, FR7

| Task | Who |
|---|---|
| `StockPort`: products, stock and low-stock from the views, adjustments including opening stock | Shammah |
| Quick sale: `entry_item` rows in the same transaction; the ledger computes the amount from lines | Shammah |
| UI: move the basket total behind the port; stock-purchase flow if D2(a) | Claude |

**Done when** the contract tests pass, selling 3 bread reduces stock by 3, and low stock appears
on the Stock tab.

### Phase 5 — Sync, backend, dashboard (3–4 days): FR9, FR10, NFR4

| Task | Who |
|---|---|
| Backend project in `backend/`, PostgreSQL tables from the schema, the sync endpoint's request/response contract and its tests, deployment config | Claude |
| Server rule: store each UUID once (idempotent), last-writer-wins for product edits | Shammah |
| Phone: outbox reader, batching, pending → in-flight → acked/failed, back-off | Shammah |
| WorkManager job wiring (runs only when online), `SyncPort` status for the badge and sheet | Claude |
| Interrupted-sync harness for NFR4 (kills the connection mid-batch, checks nothing is lost or doubled) | Claude |
| Read-only dashboard (FR10, Could) | Claude (UI); queries Shammah |

**Done when** records made offline appear once on the server after the phone reconnects, and
the NFR4 harness reports zero loss and zero duplicates over N runs.

### Phase 6 — ML: categoriser and anomaly detection (last; starts when the seed corpus is in)

| Task | Who |
|---|---|
| Seed-corpus intake: CSV template, a validator (codebook, provenance column, no names), and the template/real split held out for testing | Claude (tooling) |
| Corpus expansion, training, evaluation, export | Shammah |
| Dart categoriser and anomaly detector behind the existing interfaces; parity test Python ↔ Dart (NFR8) | Shammah (Claude writes the parity harness) |
| "Usually about K…" from the detector's result | Shammah |
| Benchmark harness: latency p50/p95, model size, memory on both low-end phones, one CSV row per run, figures generated (NFR1, NFR2) | Claude (harness); runs on your phones |
| Researcher mode showing confidence and latency (D8) | Claude |

**Done when** the parity test passes in CI, FR3 and FR4 work in airplane mode, and the benchmark
CSV holds measured rows from both test phones.

### Phase 7 — Usability round and Chapter 4 evidence

Usability sessions T1–T4 (NFR5). This needs phase 6 for T3. Then the evidence: re-rendered
screens (`tool/screens`), test reports, benchmark figures and the ERD from the schema.

## 5. Fitting it into 16 days

| Days | Phase |
|---|---|
| 26–27 Oct | 1 Foundations |
| 28–31 Oct | 2 Ledger core |
| 1–2 Nov | 3 Onboarding |
| 3–4 Nov | 4 Stock and quick sale |
| 5–8 Nov | 5 Sync (cut the dashboard first if behind) |
| from seed corpus | 6 ML, then 7 usability |

**The main risk:** with ML last, FR3 (a Must) and usability task T3 depend on when the seed
corpus arrives. If it is not in by about 3 November, the ML phase and the usability round will
not both fit before 10 November. Two ways out:
1. Agree with your supervisor that 10 November shows phases 1–5, with ML and usability after.
2. Run the ML phase on the synthetic corpus first, to unblock T3 and the benchmark, and retrain
   on the seeded corpus when it arrives. Chapter 3 already limits the accuracy claims of
   synthetic data.

## 6. Other risks

- **Logic volume versus time under D1(a).** Phases 2, 4 and 5 are mostly your code. The contract
  tests keep it targeted, but they don't reduce it.
- **Low-end test phones.** Your Galaxy S24+ does not represent the target devices. The two 2–4 GB
  phones are needed for NFR1, NFR2 and NFR7 well before the ML phase ends.
- **Release signing.** Participant phones need a release keystore you create and keep private.
  The debug key is fine for development only.
- **Public repository.** No participant data, consent records or keys may enter it. CI should check
  for `ml/data/raw/`.
