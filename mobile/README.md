# SFM-LCP mobile app

The Android app for market traders: record sales and expenses, see today's totals, keep stock,
all offline. This folder holds the **full UI**, built from
[`docs/design/ui-design-brief.md`](../docs/design/ui-design-brief.md). The data, ledger,
categoriser, anomaly detector and sync are the next phase. The UI talks to them only through the
interfaces in `lib/app/ports.dart`.

## Run it

```bash
cd mobile
flutter run
```

Until the real data layer exists, `main.dart` starts the app on **preview data**
(`lib/preview/preview_ports.dart`): five sample entries, four products and fixed totals. Preview
data is a stand-in. Totals don't change when you record something, only two sample phrases get a
category suggestion ("bus fare to Matero", "Repair of wheelbarrow"), and nothing survives a
restart.

## Layout

```
lib/
  main.dart                 wires the app to its ports (preview for now)
  app/
    ports.dart              ← the contract: what the UI needs from the data and domain layers
    view_data.dart          shapes the screens display and the drafts they hand back
    ports_scope.dart        makes the ports available to every screen
    app.dart                theme + first-launch routing
  core/
    theme/tokens.dart       every colour, size, radius and type style (brief §3–5)
    theme/app_theme.dart    Material theme built from the tokens
    format/                 kwacha and date formatting; keypad text → ngwee
  ui/
    categories.dart         codebook names and icons
    widgets/                keypad, chips, money text, attention card, entry tile, …
    screens/                one file per screen (below)
  preview/preview_ports.dart  sample data for running and reviewing the UI
test/                       unit + widget tests (flows, no-overflow at 360 dp and 1.3× text)
tool/screens/               renders every screen to docs/screens/
```

## Screens

| Brief ID | Screen | File |
|---|---|---|
| S01 | Participant code | `participant_screen.dart` |
| S02 + S08 | Today, with the "Is this right?" check | `today_screen.dart` |
| S03 / S04 | Record sale (amount or products) | `entry_screen.dart` |
| S05 | Record expense, with suggestion | `entry_screen.dart` |
| S06 | All categories sheet | `widgets/choices.dart` |
| S07 | Saved banner | `widgets/building_blocks.dart` |
| S09 / S10 | Entry detail, cancel confirmation | `entry_detail_screen.dart` |
| S11 | Totals, day and week | `totals_screen.dart` |
| S12 | Stock list | `stock_screen.dart` |
| S13 | New product | `product_form_screen.dart` |
| S14 | Adjust stock | `adjust_stock_screen.dart` |
| S15 | Sync and account sheet | `widgets/ledger_widgets.dart` |
| — | Tab bar (Today, Totals, Stock) | `app_shell.dart`, `tab_scaffold.dart` |

Rendered images of every screen are in [`docs/screens/`](../docs/screens/).

## The next phase: implementing the ports

Each interface in `lib/app/ports.dart` maps to a part of Chapter 3:

| Port | What it does | Chapter 3 |
|---|---|---|
| `SessionPort` | Read and save the participant code (`business` row) | FR11 |
| `LedgerPort` | Today's entries, record sale/expense, cancel by reversal, change category, unusual-entry answers | FR1, FR2, FR4, FR12 |
| `TotalsPort` | Day and week totals (`v_daily_summary`) | FR5 |
| `CategoryPort` | On-device category suggestion | FR3 |
| `StockPort` | Products, low-stock flags (`v_low_stock`), adjustments | FR6, FR7 |
| `SyncPort` | Records waiting in the outbox, last sync time | FR9 |

Implement them in `lib/data/` and `lib/domain/`, build an `AppPorts` from them in `main.dart`,
and every screen switches over with no UI change. The UI never computes a ledger rule: totals,
"usually about" amounts, low-stock flags and suggestions all arrive ready-made through the
ports. The only arithmetic in the UI is display arithmetic (the quick-sale basket total and the
"new stock" preview), which you may prefer to move behind `LedgerPort` / `StockPort`.

## Checks

```bash
flutter analyze
flutter test
flutter test --update-goldens tool/screens   # re-render docs/screens/
```

The widget tests drive each flow on the preview data. They also scroll every screen on a
360×640 phone at 1.3× text size and fail on any layout overflow.

## Fonts

The brief specifies Atkinson Hyperlegible. Until its font files are added under `assets/fonts/`,
the app uses Roboto (Android's system font). Switching is one line: `AppText.family` in
`lib/core/theme/tokens.dart`, plus the `fonts:` entry in `pubspec.yaml`.
