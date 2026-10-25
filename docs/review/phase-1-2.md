# Review guide — Phases 1 and 2: database and ledger core

Branch `feature/data-layer`. Written by Claude Code under the 25 Oct 2026 working agreement;
record it in the AI assistance log. Read this file, then the code in the order listed in section 2.

## 1. What changed for the user

The app now saves to a real database on the phone instead of sample data.

| Works now | Requirement |
|---|---|
| Participant code saved on first launch; the app opens on Today after that | FR11 |
| Record a sale or an expense; it survives a restart | FR1, FR2, FR8 |
| Today's list and the Money in / Money out / Profit strip, in Lusaka time | FR1, FR2, FR5 |
| Totals by day and by week (Monday to Sunday) with per-category rows | FR5 |
| Cancel a mistake: a reversing entry is added and the original shows "Cancelled" | FR12 |
| Change the category of a saved entry | FR3 |
| Products, stock levels, low-stock warning, stock adjustments | FR7 |
| Quick sale from products: the ledger prices the items and stock goes down | FR6 |
| Sync badge counts records waiting in the outbox | FR9 (status only) |

Not yet: category suggestions and unusual-entry checks (ML phase; until then the user always
picks the category and nothing is flagged), onboarding beyond the code (Phase 3), recording
products bought on an expense (Phase 4), sending anything to the server (Phase 5).

## 2. How it fits together

```
UI screens ──► ports.dart (interfaces) ◄── data/*_repository.dart ──► AppDatabase (Drift)
                                                │                         │
                                     domain/models.dart          schema.drift ← schema.sql
                                  (Categoriser, AnomalyDetector    (Chapter 3, unchanged)
                                   interfaces + "no model" versions)
```

Read in this order:

1. `mobile/lib/data/schema.sql`: your Chapter 3 schema, byte for byte. `schema.drift` is built
   from it (one comment and the PRAGMA line differ; the header says why).
2. `mobile/lib/data/database.dart`: opens the database, creates every table, trigger and view,
   seeds the 11 categories from `domain/codebook.dart`, and turns foreign keys on.
3. `mobile/lib/data/lusaka_time.dart`: what "today" and "this week" mean (UTC+2, Monday start).
4. `mobile/lib/data/session_repository.dart`: the participant (`business` row).
5. `mobile/lib/data/ledger_repository.dart`: recording, cancelling, changing a category,
   unusual entries. The core of the phase.
6. `mobile/lib/data/totals_repository.dart`: day and week totals.
7. `mobile/lib/data/stock_repository.dart`: products, stock, adjustments.
8. `mobile/lib/app/app_ports.dart`: where all of the above is assembled; `main.dart` calls it.

## 3. Where each rule lives

Most rules are enforced by **your schema**, not by Dart code. The Dart code checks some of them
first only to give clear errors.

| Rule | Enforced by | Test |
|---|---|---|
| An expense needs a description | Schema CHECK, and checked first in `_record` | `an expense needs a description` |
| Amounts above zero; reversals negative | Schema CHECK, and checked first in `_record` | `the amount must be above zero` |
| Sale ↔ income category, expense ↔ expense category | Schema trigger on insert; **Dart on update** (see 4.1) | `a sale cannot take an expense category…`, `is refused across kinds…` |
| Entries are never deleted or edited (except category) | Schema triggers | `ledger entries cannot be deleted`, `financial fields cannot be edited` |
| A reversal cancels its original exactly, once | Schema trigger and UNIQUE | `an entry can be cancelled only once…` |
| Every change is queued for sync in the same transaction | Schema triggers | `…queued for sync once`, `every change is queued in the outbox…` |
| Prediction stored beside the user's choice | `_record` writes `predicted_category`, `category_confidence`, `model_version` | `an expense is saved with its prediction…` |
| Totals are net of cancellations | Sum of all rows (reversals are negative) | `day totals are net of cancellations and match v_daily_summary` |
| Stock is derived, never stored | Schema views `v_stock_level`, `v_low_stock` | `stock is derived…`, `a new product starts with its opening stock…` |
| No selling more than is in stock; no adjusting below zero | Dart (`_priceLines`, `adjust`) | `cannot sell more than is in stock`, `adjustments change stock but never below zero` |

The schema's own tests from Chapter 3 now run against the app's database:
`mobile/test/data/schema_test.dart`. The repository rules are in
`mobile/test/data/repositories_test.dart`, one named test per rule.

## 4. Decisions to check

### 4.1 A gap in the schema (suggested change to Chapter 3)

`trg_category_kind` runs **BEFORE INSERT** only. Changing the category of a saved entry is an
UPDATE, so the schema would accept an expense category on a sale. The Dart code checks it
(`changeCategory`). Suggested addition to `schema.sql`, if you agree:

```sql
CREATE TRIGGER trg_category_kind_update BEFORE UPDATE OF final_category ON ledger_entry
BEGIN
  SELECT RAISE(ABORT, 'category kind does not match entry type')
  WHERE (SELECT kind FROM category WHERE code = NEW.final_category)
        <> CASE NEW.entry_type WHEN 'sale' THEN 'income' ELSE 'expense' END;
END;
```

### 4.2 Something the schema forced: reversals repeat the description

The CHECK "an expense must say what it was for" applies to **every** expense row, reversals
included. A reversal with an empty description is rejected, so cancelling an expense would fail.
The reversal therefore copies the original's description. Chapter 3's Python tests only reversed
a sale, which is why this did not show up there. It was found by `posts an exact reversal…`.

### 4.3 Choices you may want to change

| Choice | Why | Where |
|---|---|---|
| A reversal takes the **original's** `occurred_at` | Cancelling yesterday's mistake corrects yesterday's totals, not today's | `cancelEntry` |
| Reversal rows are never listed; the original shows "Cancelled" | Fewer rows for low-literacy users | `_entryColumns`, `watchToday` |
| Counts ("3 entries") exclude cancelled entries; amounts are net | Matches what the user sees in the list | `totals_repository.dart` |
| A quick sale is priced from **current** product prices; the screen's total is ignored | The ledger, not the UI, owns the amount | `recordSale`, `_priceLines` |
| Selling more than is in stock is refused | Keeps stock non-negative; a stock count fixes errors | `_priceLines` |
| The anomaly detector sees 60 days of history, excluding cancelled entries | A placeholder until the ML phase decides | `historyWindow` |
| "Today" is fixed when the screen opens | If the app stays open past midnight, Today shows yesterday until reopened | `watchToday` |

## 5. Known limits after this phase

- With no categoriser, an expense shows only the "Other" chip, so picking a category takes two
  taps. Showing the expense categories directly when there is no suggestion is a small UI change.
  Say if you want it before the ML phase.
- The UI test suite and the screenshots still use the preview data (`lib/preview/`), on purpose:
  they test screens, not storage.
- Nothing leaves the phone yet. The sync badge counts records waiting.

## 6. How to check it yourself

```bash
cd mobile
dart run build_runner build     # generates database.g.dart from schema.drift
flutter test test/data          # 43 data-layer tests: schema rules + repositories
flutter test                    # everything (79)
flutter run                     # on your phone: data now survives a restart
```

On the phone, try: record a sale and an expense, close the app fully, reopen. Then switch to
airplane mode and do it again (NFR3). Then cancel the expense and check Today's strip and the
Totals tab both drop by its amount.
