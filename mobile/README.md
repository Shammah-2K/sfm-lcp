# SFM-LCP mobile app

The Android app for market traders: record sales and expenses, see today's totals, keep stock,
all offline, and sync a copy to the study server when there is network. The UI is built from
[`docs/design/ui-design-brief.md`](../docs/design/ui-design-brief.md) and talks to the rest of
the app only through the interfaces in `lib/app/ports.dart`. The categoriser and anomaly
detector are the models trained in `../ml/`, bundled in `assets/models/` and run in pure Dart.

## Run it

```bash
cd mobile
flutter pub get
dart run build_runner build                                   # Drift code, once and after schema changes
flutter run --release --dart-define-from-file=supabase.json   # with sync (see ../backend/README.md)
flutter run                                                   # offline only
```

Other entry points: `lib/demo/demo_main.dart` (the demo app with sample records, see the root
README) and `lib/bench/bench_main.dart` (the on-device benchmark, see `../bench/README.md`).

`lib/preview/preview_ports.dart` holds fixed sample data, used only by the UI tests and the
screen renders.

## Layout

```
lib/
  main.dart                 opens the database, loads the models, wires the ports (app_ports.dart)
  data/                     Drift database (schema.sql), ledger, totals, stock, session repositories
  domain/                   the categoriser and detector (pure Dart), model loading
  sync/                     sync worker, foreground scheduler, Supabase client
  demo/, bench/             the demo app and benchmark entry points
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

## The ports

Each interface in `lib/app/ports.dart` maps to a part of Chapter 3, and is implemented in
`lib/data/`, `lib/domain/` and `lib/sync/` (assembled in `lib/app/app_ports.dart`):

| Port | What it does | Chapter 3 |
|---|---|---|
| `SessionPort` | Read and save the participant code (`business` row) | FR11 |
| `LedgerPort` | Today's entries, record sale/expense, cancel by reversal, change category, unusual-entry answers | FR1, FR2, FR4, FR12 |
| `TotalsPort` | Day and week totals (`v_daily_summary`) | FR5 |
| `CategoryPort` | On-device category suggestion | FR3 |
| `StockPort` | Products, low-stock flags (`v_low_stock`), adjustments | FR6, FR7 |
| `SyncPort` | Records waiting in the outbox, last sync time | FR9 |

The UI never computes a ledger rule: totals, "usually about" amounts, low-stock flags and
suggestions all arrive ready-made through the ports. The only arithmetic in the UI is display
arithmetic (the quick-sale basket total and the "new stock" preview).

## Checks

```bash
flutter analyze
flutter test
flutter test --update-goldens tool/screens   # re-render docs/screens/
```

The widget tests drive each flow on the preview data. They also scroll every screen on a
360×640 phone at 1.3× text size and fail on any layout overflow.

## Fonts

The app uses Roboto, Android's system font. The brief's Atkinson Hyperlegible was tried and
reverted (27 Oct 2026). Changing the family is one line, `AppText.family` in
`lib/core/theme/tokens.dart`, plus a `fonts:` entry in `pubspec.yaml` for a bundled font.
