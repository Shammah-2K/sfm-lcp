# Review guide — Phase 4: stock bought on an expense

Branch `feature/data-layer`. Written by Claude Code under the 25 Oct 2026 working agreement;
record it in the AI assistance log. Decision D2 ("expense flow that records products bought").

## 1. What changed for the user

| Change | Requirement |
|---|---|
| An expense in **Stock purchase** shows **Products bought**: add a product, how many, cost of one | FR7 |
| Saving raises each product's stock by the quantity bought | FR6, FR7 |
| The amount **defaults to the products' total**; typing on the keypad overwrites it (discount, delivery) | FR2 |
| After overwriting, "Use K… as the amount" switches back to the total | usability |
| No description needed with products: it is saved as e.g. "10 × Bread" | schema CHECK |
| "New product" from the purchase opens the product form **without "Stock now"** | FR7 |
| A purchase cannot be cancelled once some of its stock has been sold | FR12 |

Screens: `docs/screens/s05c_stock_purchase.png`, `s05d_purchase_line.png`.

## 2. Read in this order

1. `mobile/lib/app/view_data.dart`: `PurchaseLine` and `ExpenseDraft.lines`.
2. `mobile/lib/data/ledger_repository.dart`: `recordExpense`, `_checkPurchaseLines`, and the
   guard at the top of `cancelEntry`.
3. `mobile/lib/ui/screens/entry_screen.dart`: `_buyingStock`, `_amountFollowsLines`,
   `_boughtSection`, `_boughtSummary`.
4. `mobile/lib/ui/screens/purchase_line_screen.dart`: the product picker and the line screen.
5. `mobile/lib/ui/screens/product_form_screen.dart`: `forPurchase`.

## 3. Decisions to check

### 3.1 No schema change

A purchase line is an `entry_item` row on an `expense` entry, with `unit_price_ngwee` holding
what the trader **paid** for one item. Chapter 3's `v_stock_level` already counts expense items
as stock in, so stock rises with no new SQL. Note in the data dictionary that
`entry_item.unit_price_ngwee` is the selling price on a sale and the cost price on a purchase.

### 3.2 The amount is not recomputed

`recordExpense` stores the amount the trader confirmed, even when it differs from the lines'
total. The lines record **what came in**; the amount records **what was paid**. Test:
`the trader may pay a different total than the lines add up to`.

### 3.3 Rules enforced in Dart (`_checkPurchaseLines`)

Lines only on category `stock`; quantity above 0; cost 0 or more; each product once; the
product belongs to this business. Any failure saves nothing.

### 3.4 Cancelling a purchase

The reversal takes the stock back out. If that would leave a product below zero (some was sold
already), the cancel is refused with "adjust the stock instead". Test:
`a purchase whose stock has since been sold cannot be cancelled`. The entry-detail screen shows
its general error in that case; a dedicated message is a small follow-up if you want one.

### 3.5 Changing category after adding products

The lines are kept on screen but hidden and **not saved** unless the category is Stock purchase,
so a mis-tap on another category loses nothing and saves nothing wrong.

## 4. Tests

| File | What it covers |
|---|---|
| `test/data/purchase_test.dart` (9) | stock rises, cost kept per line, amount overwrite, bad lines refused, cancel, cancel refused, totals |
| `test/purchase_flow_test.dart` (2) | the screen on the real database: default amount, overwrite, switch back, saved description, new product without opening stock |
| `test/app_flow_test.dart` (1 new) | no overflow on both new screens at 360×640 and 1.3× text |

## 5. Check it yourself

```bash
cd mobile
flutter test                     # 107 tests
flutter run
```

On the phone: Expense → Other → Stock purchase → Add product → pick one, 10, cost 20 → Add.
The amount shows K200. Type 185 → "Use K200.00 as the amount" appears. Save; the Stock tab
shows the product 10 higher.
