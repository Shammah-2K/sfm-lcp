# SFM-LCP study dashboard (FR10, UC12)

A read-only web page for the researcher: who has started or withdrawn, records received, and for
each participant their ledger, money in and out by Lusaka day, categories and stock. It reads the
copy that phones sync to Supabase; it cannot change anything.

UC12's actor is the **researcher** (changed from "business owner" on 29 Oct 2026: traders have no
web sign-in under decision D6, and participant codes are not secrets).

## Set up (once)

1. **Run the migration** `backend/supabase/migrations/20261029000000_dashboard.sql` in the
   Supabase SQL editor (after the sync migration).
2. **Create your account:** Authentication → Users → *Add user* → *Create new user* (your email
   and a strong password; tick *Auto Confirm User*).
3. **Put it on the researcher list** (SQL editor):

   ```sql
   insert into public.researcher (user_id)
   select id from auth.users where email = 'you@example.com';
   ```

4. **Config:** copy `config.example.js` to `config.js` (git-ignored) and fill in the Project URL
   and the publishable key, the same values as `mobile/supabase.json`.

## Open it

Double-click `index.html`, or serve the folder:

```bash
python -m http.server 8765 --directory dashboard   # then http://localhost:8765
```

To publish it (e.g. GitHub Pages), `config.js` must be published too. That is safe: the
publishable key is public by design, and the data is readable only by accounts in
`public.researcher`. Never use the secret / service_role key here.

## What it shows

| Screen | Content |
|---|---|
| Overview | Codes issued, started, withdrew, entries received, last record received; one row per code with status, business type, entries, cancellations, money in and out, unusual entries, last received |
| Participant | Money in, out and profit; a bar chart of money in and out per Lusaka day (or the same as a table); totals by category; stock per product (low and stopped products marked); the ledger, newest first, with cancelled entries struck through and unusual ones marked |

Amounts are exact (decision D7: round any figure you publish). Money is net of cancellations,
because a cancellation is a negative row. The numbers come from views in the migration
(`dash_participant`, `dash_daily`, `dash_category`, `dash_stock`), which are tested in
`backend/supabase/tests/dashboard_test.sql`.
