# SFM-LCP study backend (Supabase)

The server keeps a copy of each participant's records for the study (FR9). The phone stays the
source of truth and works offline; the copy is filled by the app's sync worker
(`mobile/lib/sync/`).

```
backend/supabase/
  migrations/20261027000000_sync.sql   tables, security, and the four functions the app calls
  seed_codes.sql                       the researcher-issued participant codes (LSK01–LSK20)
```

## Set up (once)

1. **Create a Supabase project** in your account. Pick the region nearest Lusaka from those
   offered.
2. **Turn on anonymous sign-ins:** Authentication → Sign In / Providers → *Allow anonymous
   sign-ins*. Each install signs in this way; nobody types a password.
3. **Create the tables and functions:** SQL Editor → paste all of
   `migrations/20261027000000_sync.sql` → Run.
4. **Add the participant codes:** SQL Editor → paste `seed_codes.sql` → Run. Change the
   prefix or count there first if your study uses different codes.
5. **Give the app the address:** copy `mobile/supabase.example.json` to `mobile/supabase.json`
   (git-ignored) and fill in the **Project URL** and the **anon / public** key from Project
   Settings → API. Build with it:

   ```bash
   cd mobile
   flutter run --release --dart-define-from-file=supabase.json
   ```

   A build without that flag works offline only, and the account sheet says so.

**Never** put the `service_role` key in the app, in `supabase.json`, or in the repo (it is
public). It bypasses every rule below.

## How a phone proves who it is (decision D6)

| Step | What happens |
|---|---|
| Onboarding, with network | `check_code` says whether the code is on the list and free; a bad code is caught on the spot |
| Onboarding, offline | The code is accepted; the first sync checks it |
| First sync | The install signs in anonymously and `claim_code` binds the code to it. One install per code |
| Every sync | `sync_push` applies a batch from the phone's outbox, all or nothing |
| "Stop taking part" | `withdraw` deletes everything that install sent and marks the code withdrawn |

Tables have row-level security on and **no policies**, so the REST API cannot read or write them
directly; only the four functions are callable by the app (`release_code` is not).

## Researcher tasks (SQL Editor)

```sql
-- Who has started, and who withdrew
select code, claimed_at, withdrawn_at from participant_code order by code;

-- A phone shows "Your code is not on the study list": add the code it was set up with
insert into participant_code (code) values ('ABC123');

-- A new phone for a participant (lost phone, reinstall): free the code for it.
-- Records already sent stay on the server under the old install.
select release_code('LSK05');

-- Records received per participant
select b.participant_code, count(*) as entries
from ledger_entry e join business b on b.id = e.business_id
group by 1 order by 1;
```

## Rules the server keeps (Chapter 3)

- Primary keys are the phone's UUIDs, so a batch sent twice (a lost reply, a retry) stores
  nothing twice (NFR4).
- Ledger entries, item lines and stock changes are append-only. The only later changes to an
  entry (category, unusual-entry answer) and product edits are last-writer-wins on `updated_at`.
- Every row must belong to the caller's own business, or the whole batch is refused.
- No names or phone numbers (NFR6). The participant code is the only identifier.
