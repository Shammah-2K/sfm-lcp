# Review guide: the demo app

Branch `feature/demo`. Written by Claude Code (5 Nov 2026); record it in the AI assistance log.
A copy of the app with three weeks of sample records, for showing it (supervision, viva). It is
not part of the study and adds no requirement.

## What it is

- **"SFM-LCP Demo",** a separate Android app (`zm.ac.zcas.sfm_lcp.demo`) beside the study app.
  The two share nothing: different package, different database file (`sfm_lcp_demo`).
- **The real app, seeded.** Same screens, ledger rules, categoriser and detector. You can record
  entries live during a demo, and totals, stock and suggestions respond.
- **Never syncs.** `lib/demo/demo_main.dart` builds no sync scheduler, whatever the build defines,
  so sample data cannot reach Supabase. The account sheet says the copy does not send records. The
  badge counts the records "waiting", which is accurate: they never leave the phone.

## What the sample shows

Trader `DEMO01`, a Soweto market stall, 21 days:

| Screen | Shows |
|---|---|
| Today | The morning's entries (always before the time you open it), and **"Is this right?"** on a K250 taxi where transport is usually about K25 |
| Totals | Sales and expenses every day, week views |
| Stock | 7 products, Kapenta **out**, Cooking oil **low** |
| Entries | Product and cash sales, cash and mobile money, every expense category in use, a stock purchase every few days, one **cancelled** entry |

Past entries the detector flagged are answered "Yes, keep it" by the seed, as a trader would on
the day. With the current models that was **1** entry in three weeks (a K10 single-item sale), so
only today's taxi waits.

## Build, install, reset

```bash
cd mobile
flutter build apk --release -t lib/demo/demo_main.dart -P sfmDemo=true
adb install -r build/app/outputs/flutter-apk/app-release.apk
```

Without `-P sfmDemo=true` the build would install over the study app (same package), though it
would still keep its own database file. **To start a demo afresh:** Settings → Apps → SFM-LCP
Demo → Storage → Clear data; the next launch seeds again.

## Read in this order

1. `mobile/lib/demo/demo_seed.dart`: what is seeded, through the real repositories.
2. `mobile/lib/demo/demo_main.dart`: the entry point (no sync).
3. `mobile/android/app/build.gradle.kts`: the `sfmDemo` switch; normal builds are unchanged.
4. `mobile/lib/domain/load_models.dart`: model loading, now shared by both apps.

## Tests

`test/demo/demo_seed_test.dart` (10): the demo trader; seeding twice is a no-op; every one of 21
days has sales and expenses; the "Is this right?" check is today's taxi with a usual amount;
today's entries are never after "now", including when opened just after midnight; one
cancellation; one product out and one low; predictions stored; nothing about the study server set.
