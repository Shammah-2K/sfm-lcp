-- Tests for migrations/20261027000000_sync.sql, run by tests/run.sh after
-- the stub, the migration and the seed. Any failed check stops the run
-- (psql -v ON_ERROR_STOP=1) with a message saying which.
--
-- Callers are simulated as Supabase does it: a role (anon or authenticated)
-- and the user id in request.jwt.claim.sub.
\set QUIET on
\set ON_ERROR_STOP on

insert into auth.users (id) values
  ('00000000-0000-0000-0000-00000000000a'),  -- phone A
  ('00000000-0000-0000-0000-00000000000b'),  -- phone B
  ('00000000-0000-0000-0000-00000000000c');  -- phone C, never claims

-- act as a signed-in install, or as an anonymous caller (no sign-in)
create function pg_temp.as_user(u text) returns void language sql as $$
  select set_config('request.jwt.claim.sub', u, false);
  set role authenticated;
$$;
create function pg_temp.as_anon() returns void language sql as $$
  select set_config('request.jwt.claim.sub', '', false);
  set role anon;
$$;
create function pg_temp.as_admin() returns void language sql as $$
  reset role;
$$;

-- fails unless sql raises an error containing expected
create function pg_temp.expect_error(sql text, expected text) returns void
language plpgsql as $$
begin
  execute sql;
  raise exception 'FAILED: expected an error containing "%" from: %', expected, sql;
exception when others then
  if sqlerrm like 'FAILED:%' then raise; end if;
  if position(expected in sqlerrm) = 0 then
    raise exception 'FAILED: expected "%" but got "%" from: %', expected, sqlerrm, sql;
  end if;
  raise notice 'ok   refused (%): %', expected, left(regexp_replace(sql, '\s+', ' ', 'g'), 60);
end;
$$;

create function pg_temp.check(ok boolean, what text) returns void
language plpgsql as $$
begin
  if not ok then raise exception 'FAILED: %', what; end if;
  raise notice 'ok   %', what;
end;
$$;
grant execute on all functions in schema pg_temp to anon, authenticated;

-- A batch from phone A: a business, a product with opening stock, a sale of
-- 2 by product, an expense and its cancellation.
create temp table batch_a as select $j${
  "business": [{"id": "biz-a", "participant_code": "LSK01", "business_type": "shop", "created_at": 1000}],
  "product": [{"id": "p1", "business_id": "biz-a", "name": "Bread", "unit_price_ngwee": 2500,
               "reorder_level": 2, "is_active": 1, "created_at": 1000, "updated_at": 1000}],
  "ledger_entry": [
    {"id": "rev1", "business_id": "biz-a", "entry_type": "expense", "amount_ngwee": -1500,
     "description": "Water", "payment_method": "cash", "predicted_category": null,
     "category_confidence": null, "final_category": "utilities", "model_version": null,
     "anomaly_score": null, "anomaly_flag": 0, "anomaly_reviewed_at": null,
     "reverses_id": "e2", "occurred_at": 1200, "created_at": 1300, "updated_at": 1300},
    {"id": "e1", "business_id": "biz-a", "entry_type": "sale", "amount_ngwee": 5000,
     "description": "", "payment_method": "cash", "predicted_category": null,
     "category_confidence": null, "final_category": "sales_goods", "model_version": null,
     "anomaly_score": null, "anomaly_flag": 0, "anomaly_reviewed_at": null,
     "reverses_id": null, "occurred_at": 1100, "created_at": 1100, "updated_at": 1100},
    {"id": "e2", "business_id": "biz-a", "entry_type": "expense", "amount_ngwee": 1500,
     "description": "Water", "payment_method": "mobile_money", "predicted_category": "utilities",
     "category_confidence": 0.9, "final_category": "utilities", "model_version": "v0",
     "anomaly_score": 0.1, "anomaly_flag": 0, "anomaly_reviewed_at": null,
     "reverses_id": null, "occurred_at": 1200, "created_at": 1200, "updated_at": 1200}],
  "entry_item": [{"id": "i1", "entry_id": "e1", "product_id": "p1", "quantity": 2, "unit_price_ngwee": 2500}],
  "stock_adjustment": [{"id": "a1", "product_id": "p1", "quantity_delta": 10, "reason": "opening", "created_at": 1000}]
}$j$::jsonb as b;
grant select on batch_a to authenticated;

-- ------------------------------------------------------------- check_code
select pg_temp.as_anon();
select pg_temp.check(public.check_code('LSK01') = 'ok', 'check_code: a listed code is ok before sign-in');
select pg_temp.check(public.check_code('lsk01') = 'ok', 'check_code: lower case is accepted');
select pg_temp.check(public.check_code('NOPE1') = 'unknown', 'check_code: an unlisted code is unknown');

-- ------------------------------------------------------- what anon can't do
select pg_temp.expect_error($$select public.sync_push('{}'::jsonb)$$, 'permission denied');
select pg_temp.expect_error($$select public.claim_code('LSK01')$$, 'permission denied');
select pg_temp.expect_error($$select public.withdraw()$$, 'permission denied');
select pg_temp.check((select count(*) from public.ledger_entry) = 0, 'anon reads no rows (RLS)');

-- ------------------------------------------------------------- claim_code
select pg_temp.as_user('00000000-0000-0000-0000-00000000000a');
select pg_temp.check(public.claim_code('LSK01') = 'ok', 'claim: phone A claims LSK01');
select pg_temp.check(public.claim_code('LSK01') = 'ok', 'claim: claiming again is a no-op');
select pg_temp.check(public.claim_code('LSK02') = 'taken', 'claim: one code per install');
select pg_temp.check(public.claim_code('NOPE1') = 'unknown', 'claim: an unlisted code is unknown');
select pg_temp.check(public.check_code('LSK01') = 'ok', 'check_code: ok for the install that holds it');
select pg_temp.expect_error($$select public.release_code('LSK01')$$, 'permission denied');

select pg_temp.as_user('00000000-0000-0000-0000-00000000000b');
select pg_temp.check(public.claim_code('LSK01') = 'taken', 'claim: phone B cannot take LSK01');
select pg_temp.check(public.check_code('LSK01') = 'taken', 'check_code: taken for another install');
select pg_temp.check(public.claim_code('LSK02') = 'ok', 'claim: phone B claims LSK02');

-- --------------------------------------------------------------- sync_push
select pg_temp.as_user('00000000-0000-0000-0000-00000000000a');
select pg_temp.check(public.sync_push((select b from batch_a)) = 7,
  'push: 7 rows stored (business, product, 3 entries, item, stock change)');
select pg_temp.check(public.sync_push((select b from batch_a)) = 0,
  'push: the same batch again stores nothing (NFR4)');
select pg_temp.check((select count(*) from public.ledger_entry) = 0,
  'push: phone A cannot read the tables directly (RLS)');

select pg_temp.as_admin();
select pg_temp.check((select count(*) from public.ledger_entry) = 3, 'push: 3 entries, no duplicates');
select pg_temp.check((select count(*) from public.entry_item) = 1, 'push: 1 item line');
select pg_temp.check(
  (select owner from public.ledger_entry where id = 'e1') = '00000000-0000-0000-0000-00000000000a',
  'push: rows are owned by the sending install');

-- last-writer-wins on the fields the phone may change, never on money
select pg_temp.as_user('00000000-0000-0000-0000-00000000000a');
select public.sync_push($j${
  "ledger_entry": [{"id": "e1", "business_id": "biz-a", "entry_type": "sale", "amount_ngwee": 999999,
     "description": "", "payment_method": "cash", "predicted_category": null,
     "category_confidence": null, "final_category": "other_income", "model_version": null,
     "anomaly_score": null, "anomaly_flag": 0, "anomaly_reviewed_at": 1500,
     "reverses_id": null, "occurred_at": 1100, "created_at": 1100, "updated_at": 1500}],
  "product": [{"id": "p1", "business_id": "biz-a", "name": "Bread loaf", "unit_price_ngwee": 2800,
               "reorder_level": 3, "is_active": 0, "created_at": 1000, "updated_at": 1500}]
}$j$::jsonb);
select public.sync_push($j${
  "product": [{"id": "p1", "business_id": "biz-a", "name": "Old name", "unit_price_ngwee": 1,
               "reorder_level": 0, "is_active": 1, "created_at": 1000, "updated_at": 1400}]
}$j$::jsonb);
select pg_temp.as_admin();
select pg_temp.check(
  (select (final_category, amount_ngwee, anomaly_reviewed_at) from public.ledger_entry where id = 'e1')
    = ('other_income'::text, 5000::bigint, 1500::bigint),
  'update: newer category and answer applied; amount never changes');
select pg_temp.check(
  (select (name, unit_price_ngwee, is_active) from public.product where id = 'p1')
    = ('Bread loaf'::text, 2800::bigint, 0::smallint),
  'update: newer product edit wins, an older one is ignored');

-- refusals: the whole batch, nothing half-applied
select pg_temp.as_user('00000000-0000-0000-0000-00000000000b');
select pg_temp.expect_error($$select public.sync_push('{"product": [{"id": "px", "business_id": "biz-a",
  "name": "X", "unit_price_ngwee": 1, "reorder_level": 0, "is_active": 1, "created_at": 1,
  "updated_at": 1}]}'::jsonb)$$, 'product for another business');
select pg_temp.expect_error($$select public.sync_push('{"business": [{"id": "biz-b",
  "participant_code": "LSK01", "business_type": "shop", "created_at": 1}]}'::jsonb)$$,
  'does not match the claimed code');
select pg_temp.expect_error($$select public.sync_push('{
  "business": [{"id": "biz-b", "participant_code": "LSK02", "business_type": "service", "created_at": 1}],
  "entry_item": [{"id": "ix", "entry_id": "e1", "product_id": "p1", "quantity": 1, "unit_price_ngwee": 1}]
}'::jsonb)$$, 'item for an entry that is not yours');
select pg_temp.as_admin();
select pg_temp.check(not exists (select 1 from public.business where id = 'biz-b'),
  'refusal: the good rows in a refused batch were not kept (all or nothing)');

select pg_temp.as_user('00000000-0000-0000-0000-00000000000c');
select pg_temp.expect_error($$select public.sync_push('{}'::jsonb)$$, 'no participant code claimed');

-- phone B sends its own records normally
select pg_temp.as_user('00000000-0000-0000-0000-00000000000b');
select pg_temp.check(public.sync_push($j${
  "business": [{"id": "biz-b", "participant_code": "LSK02", "business_type": "service", "created_at": 1}],
  "ledger_entry": [{"id": "b1", "business_id": "biz-b", "entry_type": "sale", "amount_ngwee": 800,
     "description": "", "payment_method": "cash", "predicted_category": null,
     "category_confidence": null, "final_category": "sales_service", "model_version": null,
     "anomaly_score": null, "anomaly_flag": 0, "anomaly_reviewed_at": null,
     "reverses_id": null, "occurred_at": 2, "created_at": 2, "updated_at": 2}]
}$j$::jsonb) = 2, 'push: phone B stores its own records');

-- ---------------------------------------------------------------- withdraw
select pg_temp.as_user('00000000-0000-0000-0000-00000000000a');
select public.withdraw();
select public.withdraw();  -- safe to repeat
select pg_temp.check(public.claim_code('LSK01') = 'withdrawn', 'withdraw: the code cannot be claimed again');
select pg_temp.check(public.check_code('LSK01') = 'withdrawn', 'withdraw: check_code says withdrawn');
select pg_temp.expect_error($$select public.sync_push((select b from batch_a))$$, 'no participant code claimed');
select pg_temp.as_admin();
select pg_temp.check(
  (select count(*) from public.business where owner = '00000000-0000-0000-0000-00000000000a')
  + (select count(*) from public.product where owner = '00000000-0000-0000-0000-00000000000a')
  + (select count(*) from public.ledger_entry where owner = '00000000-0000-0000-0000-00000000000a')
  + (select count(*) from public.entry_item where owner = '00000000-0000-0000-0000-00000000000a')
  + (select count(*) from public.stock_adjustment where owner = '00000000-0000-0000-0000-00000000000a') = 0,
  'withdraw: everything phone A sent is deleted');
select pg_temp.check((select count(*) from public.ledger_entry) = 1, 'withdraw: phone B is untouched');
select pg_temp.check(
  (select withdrawn_at is not null from public.participant_code where code = 'LSK01'),
  'withdraw: the code row stays, marked withdrawn');

-- ------------------------------------------------------------ release_code
select public.release_code('LSK02');
select pg_temp.as_user('00000000-0000-0000-0000-00000000000c');
select pg_temp.check(public.claim_code('LSK02') = 'ok', 'release: a new phone can claim a released code');
select pg_temp.as_admin();
-- dashboard_test.sql continues in the same session, with these helpers.
