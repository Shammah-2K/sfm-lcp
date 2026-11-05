-- =====================================================================
-- SFM-LCP study backend (Supabase / PostgreSQL), Phase 5: FR9, NFR4, NFR6
--
-- The server keeps a copy of each participant's records. The phone stays the
-- source of truth (offline first); this copy is for the study.
--
-- Who may send (decision D6, 27 Oct 2026):
--   * Each install signs in anonymously (Supabase Auth): no password to type.
--   * On first connection it claims a participant code from the list the
--     researcher issued. A code is claimed by one install only; a second
--     phone is refused until the researcher releases the code.
--   * No names or phone numbers are stored here (NFR6): the code is the only
--     identifier, and the link from code to person stays on paper.
--
-- How records arrive: one call, sync_push(batch), applies a batch from the
-- phone's outbox in one transaction. Primary keys are the phone's UUIDs, so a
-- batch sent twice (a lost reply, a retry) changes nothing the second time:
-- NFR4, "no lost or duplicated records".
--
-- Tables have row-level security on and no policies: nothing is reachable
-- through the REST API except the functions below. The researcher reads the
-- data in the dashboard or with SQL.
-- =====================================================================

-- --------------------------------------------------------- participant codes
create table public.participant_code (
  code         text primary key check (code ~ '^[A-Z0-9]{4,12}$'),
  claimed_by   uuid unique references auth.users (id) on delete set null,
  claimed_at   timestamptz,
  withdrawn_at timestamptz,
  check ((claimed_by is null) = (claimed_at is null))
);
comment on table public.participant_code is
  'Codes issued by the researcher. claimed_by is the anonymous install that uses the code.';

-- ------------------------------------------------- the codebook (BUILD §3)
create table public.category (
  code       text primary key,
  name       text not null,
  kind       text not null check (kind in ('income', 'expense')),
  icon       text not null,
  sort_order integer not null default 0
);
insert into public.category (code, name, kind, icon, sort_order) values
  ('sales_goods',   'Sales of goods',      'income',  'shopping_basket', 1),
  ('sales_service', 'Service income',      'income',  'handyman',        2),
  ('other_income',  'Other income',        'income',  'savings',         3),
  ('stock',         'Stock purchase',      'expense', 'inventory_2',     4),
  ('transport',     'Transport',           'expense', 'directions_bus',  5),
  ('airtime',       'Airtime & data',      'expense', 'phone_android',   6),
  ('rent_levy',     'Rent & market fees',  'expense', 'storefront',      7),
  ('utilities',     'Electricity & water', 'expense', 'bolt',            8),
  ('wages',         'Wages',               'expense', 'groups',          9),
  ('food',          'Meals',               'expense', 'restaurant',      10),
  ('other_expense', 'Other expense',       'expense', 'more_horiz',      11);

-- ------------------------------------- mirrors of the phone's tables (Ch. 3)
-- Same columns and units as the phone (ngwee, epoch ms UTC), plus:
--   owner       the anonymous install that sent the row
--   received_at when the server first stored it
create table public.business (
  id               text primary key,
  owner            uuid not null unique references auth.users (id) on delete cascade,
  participant_code text not null references public.participant_code (code),
  business_type    text check (business_type in ('market_stall', 'shop', 'service', 'other')),
  created_at       bigint not null,
  received_at      timestamptz not null default now()
);

-- The phone keeps product names unique per business. The copy does not, so
-- that two renames arriving in either order can never block a sync.
create table public.product (
  id               text primary key,
  owner            uuid not null references auth.users (id) on delete cascade,
  business_id      text not null references public.business (id),
  name             text not null check (length(trim(name)) > 0),
  unit_price_ngwee bigint not null check (unit_price_ngwee >= 0),
  reorder_level    integer not null default 0 check (reorder_level >= 0),
  is_active        smallint not null default 1 check (is_active in (0, 1)),
  created_at       bigint not null,
  updated_at       bigint not null,
  received_at      timestamptz not null default now()
);

create table public.ledger_entry (
  id                  text primary key,
  owner               uuid not null references auth.users (id) on delete cascade,
  business_id         text not null references public.business (id),
  entry_type          text not null check (entry_type in ('sale', 'expense')),
  amount_ngwee        bigint not null,
  description         text not null default '' check (length(description) <= 120),
  payment_method      text not null default 'cash' check (payment_method in ('cash', 'mobile_money')),
  predicted_category  text references public.category (code),
  category_confidence double precision check (category_confidence between 0 and 1),
  final_category      text not null references public.category (code),
  model_version       text,
  anomaly_score       double precision,
  anomaly_flag        smallint not null default 0 check (anomaly_flag in (0, 1)),
  anomaly_reviewed_at bigint,
  reverses_id         text unique references public.ledger_entry (id),
  occurred_at         bigint not null,
  created_at          bigint not null,
  updated_at          bigint not null,
  received_at         timestamptz not null default now(),
  check (entry_type = 'sale' or length(trim(description)) > 0),
  check ((reverses_id is null and amount_ngwee > 0) or (reverses_id is not null and amount_ngwee < 0)),
  check ((predicted_category is null) = (category_confidence is null)),
  check (anomaly_flag = 0 or anomaly_score is not null)
);

create table public.entry_item (
  id               text primary key,
  owner            uuid not null references auth.users (id) on delete cascade,
  entry_id         text not null references public.ledger_entry (id),
  product_id       text not null references public.product (id),
  quantity         integer not null check (quantity <> 0),
  unit_price_ngwee bigint not null check (unit_price_ngwee >= 0),
  received_at      timestamptz not null default now(),
  unique (entry_id, product_id)
);

create table public.stock_adjustment (
  id             text primary key,
  owner          uuid not null references auth.users (id) on delete cascade,
  product_id     text not null references public.product (id),
  quantity_delta integer not null check (quantity_delta <> 0),
  reason         text not null check (reason in ('opening', 'count', 'damage', 'other')),
  created_at     bigint not null,
  received_at    timestamptz not null default now()
);

create index ix_product_owner on public.product (owner);
create index ix_entry_owner   on public.ledger_entry (owner);
create index ix_entry_time    on public.ledger_entry (business_id, occurred_at);
create index ix_item_owner    on public.entry_item (owner);
create index ix_adjust_owner  on public.stock_adjustment (owner);

-- RLS on, no policies: the REST API cannot read or write these tables directly.
alter table public.participant_code enable row level security;
alter table public.category         enable row level security;
alter table public.business         enable row level security;
alter table public.product          enable row level security;
alter table public.ledger_entry     enable row level security;
alter table public.entry_item       enable row level security;
alter table public.stock_adjustment enable row level security;

-- ---------------------------------------------------------------- functions

-- Onboarding asks this before the phone has signed in, so a mistyped code is
-- caught at once. Says only whether a code can be used; reveals nothing else.
create function public.check_code(p_code text) returns text
language sql stable security definer set search_path = public, pg_temp as $$
  select coalesce(
    (select case
              when withdrawn_at is not null then 'withdrawn'
              when claimed_by is not null and claimed_by is distinct from auth.uid() then 'taken'
              else 'ok'
            end
       from participant_code where code = upper(p_code)),
    'unknown');
$$;

-- First connection of an install: bind the code to it. Claiming again from
-- the same install is a no-op, so a lost reply can be retried.
create function public.claim_code(p_code text) returns text
language plpgsql security definer set search_path = public, pg_temp as $$
declare
  me uuid := auth.uid();
  pc participant_code;
begin
  if me is null then
    raise exception 'not signed in' using errcode = '28000';
  end if;
  select * into pc from participant_code where code = upper(p_code) for update;
  if not found then
    return 'unknown';
  end if;
  if pc.withdrawn_at is not null then
    return 'withdrawn';
  end if;
  if pc.claimed_by = me then
    return 'ok';
  end if;
  -- Taken by another phone, or this install already holds a different code.
  if pc.claimed_by is not null
     or exists (select 1 from participant_code where claimed_by = me) then
    return 'taken';
  end if;
  update participant_code set claimed_by = me, claimed_at = now() where code = pc.code;
  return 'ok';
end;
$$;

-- Applies one batch from the phone's outbox, all or nothing.
--
--   batch = { "business": [...], "product": [...], "ledger_entry": [...],
--             "entry_item": [...], "stock_adjustment": [...] }
--
-- Each row is the record as it is now on the phone, with the phone's column
-- names. Rules, matching Chapter 3:
--   * ledger entries, item lines and stock changes are append-only: a row is
--     stored once, and a resent row changes nothing;
--   * the only later changes to an entry (final_category, anomaly_reviewed_at)
--     and product edits are last-writer-wins on updated_at.
-- Every row must belong to the caller's own business; otherwise the whole
-- batch is refused, so the phone keeps it and nothing is half-applied.
create function public.sync_push(batch jsonb) returns integer
language plpgsql security definer set search_path = public, pg_temp as $$
declare
  me      uuid := auth.uid();
  my_code text;
  my_biz  text;
  applied integer := 0;
  n       integer;
begin
  if me is null then
    raise exception 'not signed in' using errcode = '28000';
  end if;
  select code into my_code
    from participant_code where claimed_by = me and withdrawn_at is null;
  if my_code is null then
    raise exception 'no participant code claimed' using errcode = '28000';
  end if;

  -- business: once per install, with the claimed code
  if exists (select 1 from jsonb_to_recordset(coalesce(batch -> 'business', '[]'))
               as x(participant_code text)
             where x.participant_code is distinct from my_code) then
    raise exception 'business row does not match the claimed code';
  end if;
  insert into business (id, owner, participant_code, business_type, created_at)
  select x.id, me, x.participant_code, x.business_type, x.created_at
    from jsonb_to_recordset(coalesce(batch -> 'business', '[]'))
      as x(id text, participant_code text, business_type text, created_at bigint)
  on conflict (id) do nothing;
  get diagnostics n = row_count; applied := applied + n;

  select id into my_biz from business where owner = me;

  -- products: insert, or last-writer-wins edit
  if exists (select 1 from jsonb_to_recordset(coalesce(batch -> 'product', '[]'))
               as x(business_id text)
             where my_biz is null or x.business_id <> my_biz) then
    raise exception 'product for another business';
  end if;
  insert into product (id, owner, business_id, name, unit_price_ngwee, reorder_level,
                       is_active, created_at, updated_at)
  select x.id, me, x.business_id, x.name, x.unit_price_ngwee, x.reorder_level,
         x.is_active, x.created_at, x.updated_at
    from jsonb_to_recordset(coalesce(batch -> 'product', '[]'))
      as x(id text, business_id text, name text, unit_price_ngwee bigint,
           reorder_level integer, is_active smallint, created_at bigint, updated_at bigint)
  on conflict (id) do update
    set name = excluded.name,
        unit_price_ngwee = excluded.unit_price_ngwee,
        reorder_level = excluded.reorder_level,
        is_active = excluded.is_active,
        updated_at = excluded.updated_at
    where product.owner = me and excluded.updated_at > product.updated_at;
  get diagnostics n = row_count; applied := applied + n;

  -- ledger entries: originals before reversals, so reverses_id always resolves
  if exists (select 1 from jsonb_to_recordset(coalesce(batch -> 'ledger_entry', '[]'))
               as x(business_id text)
             where my_biz is null or x.business_id <> my_biz) then
    raise exception 'entry for another business';
  end if;
  insert into ledger_entry (id, owner, business_id, entry_type, amount_ngwee, description,
                            payment_method, predicted_category, category_confidence,
                            final_category, model_version, anomaly_score, anomaly_flag,
                            anomaly_reviewed_at, reverses_id, occurred_at, created_at, updated_at)
  select x.id, me, x.business_id, x.entry_type, x.amount_ngwee, x.description,
         x.payment_method, x.predicted_category, x.category_confidence,
         x.final_category, x.model_version, x.anomaly_score, x.anomaly_flag,
         x.anomaly_reviewed_at, x.reverses_id, x.occurred_at, x.created_at, x.updated_at
    from jsonb_to_recordset(coalesce(batch -> 'ledger_entry', '[]'))
      as x(id text, business_id text, entry_type text, amount_ngwee bigint, description text,
           payment_method text, predicted_category text, category_confidence double precision,
           final_category text, model_version text, anomaly_score double precision,
           anomaly_flag smallint, anomaly_reviewed_at bigint, reverses_id text,
           occurred_at bigint, created_at bigint, updated_at bigint)
   order by (x.reverses_id is not null), x.created_at
  on conflict (id) do update
    set final_category = excluded.final_category,
        anomaly_reviewed_at = excluded.anomaly_reviewed_at,
        updated_at = excluded.updated_at
    where ledger_entry.owner = me and excluded.updated_at > ledger_entry.updated_at;
  get diagnostics n = row_count; applied := applied + n;

  -- item lines: append-only
  if exists (select 1 from jsonb_to_recordset(coalesce(batch -> 'entry_item', '[]'))
               as x(entry_id text)
             where not exists (select 1 from ledger_entry e
                                where e.id = x.entry_id and e.owner = me)) then
    raise exception 'item for an entry that is not yours';
  end if;
  insert into entry_item (id, owner, entry_id, product_id, quantity, unit_price_ngwee)
  select x.id, me, x.entry_id, x.product_id, x.quantity, x.unit_price_ngwee
    from jsonb_to_recordset(coalesce(batch -> 'entry_item', '[]'))
      as x(id text, entry_id text, product_id text, quantity integer, unit_price_ngwee bigint)
  on conflict (id) do nothing;
  get diagnostics n = row_count; applied := applied + n;

  -- stock changes: append-only
  if exists (select 1 from jsonb_to_recordset(coalesce(batch -> 'stock_adjustment', '[]'))
               as x(product_id text)
             where not exists (select 1 from product p
                                where p.id = x.product_id and p.owner = me)) then
    raise exception 'stock change for a product that is not yours';
  end if;
  insert into stock_adjustment (id, owner, product_id, quantity_delta, reason, created_at)
  select x.id, me, x.product_id, x.quantity_delta, x.reason, x.created_at
    from jsonb_to_recordset(coalesce(batch -> 'stock_adjustment', '[]'))
      as x(id text, product_id text, quantity_delta integer, reason text, created_at bigint)
  on conflict (id) do nothing;
  get diagnostics n = row_count; applied := applied + n;

  return applied;
end;
$$;

-- "Stop taking part": delete everything this install sent and mark the code
-- withdrawn. The code row stays, so the study can report how many withdrew.
-- Safe to call twice.
create function public.withdraw() returns void
language plpgsql security definer set search_path = public, pg_temp as $$
declare
  me uuid := auth.uid();
begin
  if me is null then
    raise exception 'not signed in' using errcode = '28000';
  end if;
  delete from stock_adjustment where owner = me;
  delete from entry_item       where owner = me;
  delete from ledger_entry     where owner = me;
  delete from product          where owner = me;
  delete from business         where owner = me;
  update participant_code set withdrawn_at = coalesce(withdrawn_at, now())
   where claimed_by = me;
end;
$$;

-- Researcher only (SQL editor): let a new phone claim a code, e.g. after a
-- lost phone or a reinstall. Records already sent stay with the old install.
create function public.release_code(p_code text) returns void
language sql security definer set search_path = public, pg_temp as $$
  update participant_code set claimed_by = null, claimed_at = null
   where code = upper(p_code);
$$;

-- Supabase grants every new function to anon and authenticated directly (not
-- only through PUBLIC), so revoke from all three, then open only what the app
-- needs. Checked by tests/sync_functions_test.sql.
revoke all on function public.check_code(text)   from public, anon, authenticated;
revoke all on function public.claim_code(text)   from public, anon, authenticated;
revoke all on function public.sync_push(jsonb)   from public, anon, authenticated;
revoke all on function public.withdraw()         from public, anon, authenticated;
revoke all on function public.release_code(text) from public, anon, authenticated;
grant execute on function public.check_code(text) to anon, authenticated;
grant execute on function public.claim_code(text) to authenticated;
grant execute on function public.sync_push(jsonb) to authenticated;
grant execute on function public.withdraw()       to authenticated;
