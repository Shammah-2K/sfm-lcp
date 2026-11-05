-- =====================================================================
-- SFM-LCP research dashboard (FR10, UC12), 29 Oct 2026
--
-- A read-only view of the synced records for the researcher (UC12's actor,
-- changed from "business owner": traders have no web sign-in, decision D6).
--
-- Who may read: accounts listed in `researcher`. Add yours once, after
-- creating it under Authentication > Users (email and password):
--   insert into public.researcher (user_id)
--   select id from auth.users where email = 'you@example.com';
--
-- Phones also sign in (anonymously), but they are not in `researcher`, so
-- these policies show them nothing. Nobody gets insert, update or delete
-- policies: the dashboard cannot change the data.
-- =====================================================================

create table public.researcher (
  user_id  uuid primary key references auth.users (id) on delete cascade,
  added_at timestamptz not null default now()
);
alter table public.researcher enable row level security;

-- security definer: reads `researcher` past its own RLS; reveals only a yes/no
-- about the caller.
create function public.is_researcher() returns boolean
language sql stable security definer set search_path = public, pg_temp as $$
  select exists (select 1 from researcher where user_id = auth.uid());
$$;
revoke all on function public.is_researcher() from public, anon, authenticated;
grant execute on function public.is_researcher() to authenticated;

-- Read-only access for researchers, table by table.
create policy researcher_reads on public.participant_code for select to authenticated using (public.is_researcher());
create policy researcher_reads on public.category         for select to authenticated using (public.is_researcher());
create policy researcher_reads on public.business         for select to authenticated using (public.is_researcher());
create policy researcher_reads on public.product          for select to authenticated using (public.is_researcher());
create policy researcher_reads on public.ledger_entry     for select to authenticated using (public.is_researcher());
create policy researcher_reads on public.entry_item       for select to authenticated using (public.is_researcher());
create policy researcher_reads on public.stock_adjustment for select to authenticated using (public.is_researcher());

grant select on public.participant_code, public.category, public.business, public.product,
  public.ledger_entry, public.entry_item, public.stock_adjustment to authenticated;

-- ------------------------------------------------------------------ views
-- security_invoker: the views run with the caller's rights, so the policies
-- above apply. (A plain view would run as its owner and bypass them.)
-- Money is net of cancellations: a reversal is a negative row of the same
-- type, so a plain SUM already removes what was cancelled.
-- Days are Lusaka days (UTC+2), as on the phone.

-- One row per code: where each participant is in the study.
create view public.dash_participant with (security_invoker = true) as
select pc.code                                         as participant_code,
       b.business_type,
       pc.claimed_at,
       pc.withdrawn_at,
       b.id                                            as business_id,
       coalesce(e.entries, 0)                          as entries,
       coalesce(e.cancelled, 0)                        as cancelled,
       coalesce(e.in_ngwee, 0)                         as in_ngwee,
       coalesce(e.out_ngwee, 0)                        as out_ngwee,
       coalesce(e.flagged, 0)                          as flagged,
       e.first_entry_at,
       e.last_entry_at,
       greatest(b.received_at, e.last_received_at, p.last_received_at) as last_received_at
  from public.participant_code pc
  left join public.business b on b.participant_code = pc.code
  left join lateral (
    select count(*) filter (where reverses_id is null)                         as entries,
           count(*) filter (where reverses_id is not null)                     as cancelled,
           coalesce(sum(amount_ngwee) filter (where entry_type = 'sale'), 0)::bigint    as in_ngwee,
           coalesce(sum(amount_ngwee) filter (where entry_type = 'expense'), 0)::bigint as out_ngwee,
           count(*) filter (where anomaly_flag = 1)                            as flagged,
           min(occurred_at)                                                    as first_entry_at,
           max(occurred_at)                                                    as last_entry_at,
           max(received_at)                                                    as last_received_at
      from public.ledger_entry where business_id = b.id
  ) e on true
  left join lateral (
    select max(received_at) as last_received_at from public.product where business_id = b.id
  ) p on true;

-- Money in and out per participant per Lusaka day (FR5, on the server copy).
create view public.dash_daily with (security_invoker = true) as
select business_id,
       (to_timestamp(occurred_at / 1000.0) at time zone 'Africa/Lusaka')::date as day,
       coalesce(sum(amount_ngwee) filter (where entry_type = 'sale'), 0)::bigint    as in_ngwee,
       coalesce(sum(amount_ngwee) filter (where entry_type = 'expense'), 0)::bigint as out_ngwee,
       count(*) filter (where reverses_id is null)                          as entries
  from public.ledger_entry
 group by 1, 2;

-- Totals per category per participant.
create view public.dash_category with (security_invoker = true) as
select e.business_id,
       e.final_category                                        as category,
       c.name,
       c.kind,
       sum(e.amount_ngwee)::bigint                             as amount_ngwee,
       count(*) filter (where e.reverses_id is null)           as entries
  from public.ledger_entry e
  join public.category c on c.code = e.final_category
 group by 1, 2, 3, 4;

-- Stock per product, derived exactly as the phone's v_stock_level.
create view public.dash_stock with (security_invoker = true) as
select p.id as product_id, p.business_id, p.name, p.unit_price_ngwee, p.reorder_level,
       p.is_active,
       (coalesce((select sum(case e.entry_type when 'expense' then i.quantity else -i.quantity end)
                   from public.entry_item i join public.ledger_entry e on e.id = i.entry_id
                  where i.product_id = p.id), 0)
     + coalesce((select sum(a.quantity_delta) from public.stock_adjustment a
                  where a.product_id = p.id), 0))::bigint as stock_qty
  from public.product p;

revoke all on public.dash_participant, public.dash_daily, public.dash_category,
  public.dash_stock from public, anon;
grant select on public.dash_participant, public.dash_daily, public.dash_category,
  public.dash_stock to authenticated;
