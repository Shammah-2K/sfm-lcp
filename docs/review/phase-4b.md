# Review guide — Phase 4b: edit a product, Stop selling

Branch `feature/data-layer`. Written by Claude Code under the 25 Oct 2026 working agreement;
record it in the AI assistance log. Closes the gap against design brief S13 ("Add / edit
product", states New and edit) and UC9 "Manage products".

## 1. What changed for the user

| Change | Source |
|---|---|
| Stock → product → **Edit** (top right of Adjust stock) opens the product form, filled in | brief S13, UC9 |
| Edit changes name, price and "warn me when below"; the count stays on Adjust stock | FR7 |
| **Stop selling**, after a confirmation, hides the product from Stock and the sale screen | UC9, data dictionary `is_active` |
| Adding a product with the name of one you stopped selling brings it back | `UNIQUE (business_id, name)` |
| A name already in your list gets "You already have … Use another name." instead of failing silently | FR6 |

Screens: `docs/screens/s13b_edit_product.png`, `s13c_stop_selling.png`, and `s14_adjust_stock.png`
(now with the Edit button).

## 2. Read in this order

1. `mobile/lib/app/ports.dart`: `StockPort.stopSelling` and `DuplicateProductName`.
2. `mobile/lib/data/stock_repository.dart`: `saveProduct` (name checks), `_bringBack`,
   `stopSelling`.
3. `mobile/lib/data/ledger_repository.dart`: `_checkPurchaseLines` now refuses a stopped
   product; `cancelEntry` skips the stock guard for one.
4. `mobile/lib/ui/screens/product_form_screen.dart`: edit mode and `_stopSelling`.
5. `mobile/lib/ui/screens/adjust_stock_screen.dart`: the Edit button.

## 3. Decisions to check

### 3.1 Hidden, never deleted

Stop selling sets `product.is_active = 0`, exactly as the data dictionary describes ("Hidden from
POS when 0; never deleted because ledger items reference it"). Past sales and purchases, totals
and Today are unchanged. The change goes into the outbox as a product `update`, so the study
copy learns of it on the next sync.

### 3.2 Where Edit lives

The brief's flow is "Stock → tap product → S14 Adjust stock", and the tests and your habits rely
on it, so it is unchanged. Edit is a labelled button on S14 (an icon alone would be harder to
recognise). If you prefer tapping a product to open Edit first, it is a two-line change.

### 3.3 Editing does not change the count

"Stock now" is hidden when editing. Every change to the count goes through Adjust stock, so each
one carries a reason (Counted, Damaged, Other) for your evaluation.

### 3.4 Selling it again

There is no "stopped products" list; adding the same name brings the old row back, with its
history. "Stock now" on that form is taken as today's count: the difference from the derived
stock is saved as a `count` adjustment. Names match exactly as typed ("bread" and "Bread" are
different products, as in the schema).

### 3.5 Old entries for a stopped product

A stopped product cannot be sold or bought (both refused). A purchase made before stopping can
still be cancelled; the "stock already sold" guard is skipped because there is no visible stock to
protect.

## 4. Tests

| File | What it covers |
|---|---|
| `test/data/stop_selling_test.dart` (8) | edit fields, new price for new sales only, duplicate names, hidden not deleted, cannot sell or buy, sent with sync, old purchase cancellable, bring back with count |
| `test/stop_selling_flow_test.dart` (3) | the screens on the real database: edit and save, duplicate-name message, confirm then gone |
| `test/app_flow_test.dart` (1 new) | no overflow on the edit form and dialog at 360×640 and 1.3× text |

## 5. Check it yourself

```bash
cd mobile
flutter test                     # 119 tests
```

On the phone: Stock → a product → Edit → change the price → Save changes. Then Edit → Stop
selling → Keep it (nothing changes) → Stop selling → Stop selling: you are back on Stock and the
product is gone. Add a product with the same name to bring it back.
