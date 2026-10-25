# Review guide — Phase 3: onboarding, font, sync badge

Branch `feature/data-layer`. Written by Claude Code under the 25 Oct 2026 working agreement;
record it in the AI assistance log.

## 1. What changed for the user

| Change | Requirement |
|---|---|
| First launch: **Welcome / consent** → participant code → type of business → Today | FR11, ethics |
| "Not now" on consent saves nothing and waits | ethics |
| The code field no longer offers word suggestions or autocorrect | FR11, usability |
| A one-time hint on Today: "Tap Sale when money comes in. Tap Expense when money goes out." | NFR5 |
| **Stop taking part** in the account sheet (tap the sync badge or the code), with a confirmation | ethics |
| The sync badge counts records the user recognises (a 3-product sale counts once) | FR9 |
| Atkinson Hyperlegible is now the app's font | design brief §4 |

Screens: `docs/screens/s00_consent.png`, `s01_participant_code.png`, `s01b_business_type.png`,
`s15_sync_sheet.png`.

## 2. Read in this order

1. `mobile/lib/data/app_state.drift`: a new local table for settings (section 3.1).
2. `mobile/lib/data/database.dart`: schema version 2 and its migration.
3. `mobile/lib/data/session_repository.dart`: consent, participant, withdrawal, hints.
4. `mobile/lib/ui/screens/onboarding_flow.dart`: the four onboarding steps.
5. `mobile/lib/app/app.dart`: which screen opens at launch.
6. `mobile/lib/data/sync_status_repository.dart`: what the badge counts.

## 3. Decisions to check

### 3.1 A table outside Chapter 3's schema

Chapter 3's `business` table has nowhere to record consent, withdrawal or dismissed hints. Rather
than change your business schema, these go in a separate table:

```sql
CREATE TABLE app_state (name TEXT NOT NULL PRIMARY KEY, value TEXT NOT NULL);
```

It has **no outbox trigger and is never synced**. A test checks this. Rows hold a timestamp, and
only the first time is kept (`consent_at`, `withdrawn_at`, `hints_dismissed_at`). Add it to the
data dictionary as "local app settings, not business data", or tell me to model consent
differently.

### 3.2 Consent wording: please check against your paper sheet

The screen says:

- This app keeps your sales, spending and stock on this phone.
- You are helping a study at ZCAS University.
- Your records are sent to the study without your name when you have network.
- You can stop at any time.

It **confirms** the paper sheet you read to the participant; it does not replace it. If your sheet
says anything different (who sees the data, how long it is kept, the language), change these
lines in `_ConsentStep` so the two agree.

### 3.3 What "Stop taking part" does now, and in Phase 5

- **Now:** records `withdrawn_at`; the badge stops counting and the account sheet says nothing more
  is sent. The ledger is untouched and the app keeps working as the trader's own record book.
- **Phase 5 (sync):** the worker must check `withdrawn` and send nothing. On its next connection it
  should send a single "delete my data" request for the participant. The dialog already promises
  that ("the study will delete what it has from you"), so Phase 5 must deliver it, or the dialog
  wording must change.

### 3.4 Upgrading a phone set up before this phase

Your phone has a participant from the Phase 2 build but no consent recorded. On upgrade:
database version 1 → 2 adds `app_state`, and the app shows **consent only**, then goes straight to
Today. Without this, the flow would have asked for a code and failed because the participant
already exists. Tests: `version 1 → 2 adds app_state…` and `a phone set up before the consent
screen…`.

### 3.5 The sync badge (fixed this phase)

| Before | After |
|---|---|
| Counted outbox **rows** | Counts **records the user recognises** with an unsent change |
| A 3-product quick sale added 4 | Adds 1 (item lines travel with their sale) |
| Editing an unsent entry twice added 2 | Adds 0 (still one record waiting) |

Failed and in-flight rows still count as waiting. Tests in `test/data/sync_count_test.dart` also
confirm the badge updates live after a save, because Drift reads the outbox triggers in
`schema.drift`.

## 4. Not done in this phase

- **Moving all text into a translation file (decision D4).** Postponed: with English only for v1,
  it touches about 150 strings for no visible change before 10 November. It costs the same later.
- **Business type** is collected but not yet used anywhere except the database (for the evaluation).

## 5. Check it yourself

```bash
cd mobile
dart run build_runner build
flutter test                     # 95 tests
flutter run                      # on your phone: you will see consent once, then Today
```

On the phone: tap the sync badge → Stop taking part → Keep going (nothing changes) → Stop taking
part → Stop (the sheet now says nothing is sent).
