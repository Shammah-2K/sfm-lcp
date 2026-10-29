# Review guide — Phase 5: sync to the study server

Branch `feature/data-layer`. Written by Claude Code under the 25 Oct 2026 working agreement;
record it in the AI assistance log. Covers FR9, NFR4, UC11 and decision D6 (agreed 27 Oct 2026:
anonymous sign-in per install, codes LSK01–LSK20, one install per code, check at onboarding when
online, server-side deletion on withdrawal). FR10 (dashboard) is not started.

**Run against your Supabase project on 29 Oct 2026:** your phone (code LSK1) signed in, claimed
its code and sent its 11 waiting records; the badge then showed all sent, and the server reported
LSK1 as taken. On the live project an anonymous caller reads no rows and is refused all
functions except `check_code`. The first attempt failed because anonymous sign-ins were still
off; the app showed nothing useful, which led to the new "Can't reach the study server" line.
The app side is also tested against an in-memory server with the same rules
(`test/sync/fake_server.dart`), and the SQL in real PostgreSQL 15 (section 5b).

## 1. What changed for the user

| Change | Requirement |
|---|---|
| Records are sent by themselves: at start, a few seconds after a save, every 5 minutes, and when the app comes back to the front | FR9 |
| **Sync now** in the account sheet when records are waiting; the sheet updates live | FR9 |
| A code not on the study list (or used on another phone) is caught at the code step when online | D6, FR11 |
| If the code is refused later, the sheet says why and to show it to the researcher | D6 |
| "Stop taking part" now asks the server to delete its copy (as the dialog promised in Phase 3) | ethics |
| A build without the server's address says "This copy of the app does not send them to the study" | — |
| After a failed try, the sheet says "Last try: no network" (normal) or "Can't reach the study server … show this to the researcher" (the server refused, e.g. sign-in switched off) | FR9, fieldwork |

## 2. Read in this order

1. `backend/supabase/migrations/20261027000000_sync.sql`: tables, `check_code`, `claim_code`,
   `sync_push`, `withdraw`, `release_code`, grants. Read the header comment first.
2. `mobile/lib/sync/sync_api.dart`: what the worker needs from a server.
3. `mobile/lib/sync/sync_worker.dart`: one sync run (the doc comment lists the steps).
4. `mobile/lib/sync/sync_scheduler.dart`: when runs happen, and back-off.
5. `mobile/lib/sync/supabase_sync_api.dart`: the HTTP calls, and `SyncConfig`.
6. `mobile/lib/data/sync_status_repository.dart`, `onboarding_flow.dart` (`_checkCode`),
   `ledger_widgets.dart` (`_SyncSheet`).
7. `backend/README.md`: your setup steps and researcher SQL.

## 3. Decisions to check

### 3.1 The worker sends records, not changes

An outbox row only says *which* record changed. The worker sends the record's **current** state
once, however many outbox rows point at it, and marks those rows acknowledged only after the
server confirms. So an entry recategorised twice offline arrives once, in its final state.

### 3.2 Why retries are safe (NFR4)

Every row keeps the UUID made on the phone. The server inserts with `ON CONFLICT (id)`: a resent
ledger entry, item or stock change is ignored; a resent product or entry edit applies only if its
`updated_at` is newer. A batch whose reply was lost is therefore sent again harmlessly. Rows left
`in_flight` by a killed app go back to `pending` at the start of the next run.

### 3.3 Order

Rows are taken oldest first, and the server applies business → products → entries (originals
before reversals) → items → stock changes inside one transaction. A sale's items never arrive
before the sale or its products, even with tiny batches (tested with batch size 1).

### 3.4 Sign-in is kept on the phone

The anonymous session (access and refresh token) is stored in the local `app_state` table, which
is never synced. It only gives access to the four functions, and only for this install's own
code. If it is ever lost (app data cleared), the phone signs in as a new install and is refused
the code as "taken" until you run `release_code`. That is decision C working as intended.

### 3.5 Sync runs only while the app is open

The plan mentioned a WorkManager background job. I did not add it: it needs a native plugin and a
second database connection in a background isolate, which is a real risk to the offline-first
guarantees 13 days before supervision. Traders open the app many times a day, and each opening,
save and resume triggers a sync. **Your call:** keep this (and say so in Chapter 5), or ask for
background sync as a follow-up.

### 3.6 A code refused after onboarding

Offline onboarding accepts any well-formed code. If the server later says it is unknown, the
phone keeps everything and retries on each run, so it recovers by itself once you add the code
(`insert into participant_code …`). There is no "change my code" screen: the code is part of the
participant's records.

### 3.7 The design brief

The code problem uses a plain ink message, not the yellow attention card, which the brief keeps
for unusual entries and low stock.

## 4. Tests

| File | What it covers |
|---|---|
| `test/sync/sync_worker_test.dart` (19) | sends all, sign-in and claim once, idle uses no network, latest state wins, reversal arrives, offline, lost reply, killed mid-run, token refresh, batch size 1, unknown code then fixed, taken code then released, withdrawal (sent, before any sync, offline then retried), onboarding check, error kept on failed rows |
| `test/sync/nfr4_harness_test.dart` (1) | the NFR4 harness (section 5) |
| `test/sync/server_contract_test.dart` (3) | the SQL reads every column the phone sends; server codebook = app codebook; grants and RLS |
| `test/sync/sync_ui_test.dart` (3) | onboarding rejects a code not on the list, then accepts LSK01; Sync now; blocked code explained |

## 5. The NFR4 harness

Each trial is one phone used at random for 40 steps (sales, expenses, purchases, cancellations,
category changes, products, stock changes, stop selling), with sync runs in between. 30% of server
calls fail (no network, reply lost after the server applied it, expired token) and the app is
sometimes "killed" mid-run. Then the network returns, and the server copy is compared with the
phone record by record: **missing** (lost), **extra** (duplicated), **stale** (old version).

The run on 27 Oct 2026 printed:

```
NFR4 harness: 50 trials, 2049 records, 695 sync runs, 1509 server calls, faults injected:
136 no network, 141 lost replies, 131 expired tokens; 190 simulated kills;
trials with lost, extra or stale records: 0
```

**Does it catch bugs?** I broke the worker on purpose (marking a batch sent when the push failed)
and ran it: 43 of 50 trials failed. The change was then undone.

**What it does not prove.** It tests the phone's half against the stand-in server. The server's
half of "no duplicates" is the `ON CONFLICT` clauses in the SQL; check those against the real
project (section 6). For Chapter 4, choose N (`--dart-define=NFR4_TRIALS=…`), run it yourself
and quote the line it prints.

## 5b. The SQL in real PostgreSQL

`bash backend/supabase/tests/run.sh` runs the migration in a throwaway `postgres:15-alpine`
container with a stand-in for Supabase's `auth` schema, roles and **default grants**, then 37
checks: code checking and claiming, a batch stored once and resent with nothing stored twice,
last-writer-wins without ever changing an amount, all-or-nothing refusals, what `anon` and the app
cannot do, withdrawal deleting one phone's data only, and `release_code`. The run on 27 Oct 2026
ended `ALL SQL CHECKS PASSED`.

**It found a real problem first.** Supabase grants every new function to `anon` and
`authenticated` directly, and the migration had only revoked from `PUBLIC`. An anonymous caller
could therefore reach `sync_push`, `claim_code` and `withdraw`. They refused anyway ("not signed
in"), but the lock-down was not what the comments claimed. The migration now revokes from all
three roles, and a test checks it.

## 6. Once your Supabase project exists

1. Follow `backend/README.md` (migration, seed, anonymous sign-ins, `supabase.json`).
2. Your phone was set up with a code from an earlier build. If it is not LSK01–LSK20, add it:
   `insert into participant_code (code) values ('YOURCODE');`
3. Build with `--dart-define-from-file=supabase.json`, install, open the account sheet, tap Sync
   now, and check the rows in the Table Editor.
4. In airplane mode, record two entries, then reconnect: they should arrive within seconds.
5. Ask me for a live check script that runs the same calls against the real project.

## 7. Check it yourself

```bash
cd mobile
flutter test                                     # 148 tests
flutter test test/sync/nfr4_harness_test.dart    # prints the NFR4 line
```
