-- Tests for migrations/20261029000000_dashboard.sql. Runs after
-- sync_functions_test.sql in the same session (its helpers and data).
-- At this point: LSK01 withdrew (phone A's data deleted); phone B holds
-- nothing (LSK02 was released to phone C); phone B's records are still there.

insert into auth.users (id) values
  ('00000000-0000-0000-0000-0000000000d1'),  -- phone D
  ('00000000-0000-0000-0000-0000000000ee');  -- the researcher
insert into public.researcher (user_id) values ('00000000-0000-0000-0000-0000000000ee');

-- Phone D, LSK03: a product with 10 opening stock, bought 5 more, sold 2;
-- a sale of K50 and a sale of K20 cancelled; an unusual expense. Times are
-- epoch ms: 1 Mar 2026 21:30 UTC is 23:30 in Lusaka (same day); 22:30 UTC
-- is already 2 Mar in Lusaka.
select pg_temp.as_user('00000000-0000-0000-0000-0000000000d1');
select pg_temp.check(public.claim_code('LSK03') = 'ok', 'dashboard: phone D claims LSK03');
select public.sync_push($j${
  "business": [{"id": "biz-d", "participant_code": "LSK03", "business_type": "market_stall", "created_at": 1772400000000}],
  "product": [{"id": "pd", "business_id": "biz-d", "name": "Kapenta", "unit_price_ngwee": 6000,
               "reorder_level": 2, "is_active": 1, "created_at": 1772400000000, "updated_at": 1772400000000}],
  "ledger_entry": [
    {"id": "d1", "business_id": "biz-d", "entry_type": "sale", "amount_ngwee": 5000, "description": "",
     "payment_method": "cash", "predicted_category": null, "category_confidence": null,
     "final_category": "sales_goods", "model_version": null, "anomaly_score": null, "anomaly_flag": 0,
     "anomaly_reviewed_at": null, "reverses_id": null,
     "occurred_at": 1772400600000, "created_at": 1772400600000, "updated_at": 1772400600000},
    {"id": "d2", "business_id": "biz-d", "entry_type": "sale", "amount_ngwee": 2000, "description": "",
     "payment_method": "cash", "predicted_category": null, "category_confidence": null,
     "final_category": "sales_goods", "model_version": null, "anomaly_score": null, "anomaly_flag": 0,
     "anomaly_reviewed_at": null, "reverses_id": null,
     "occurred_at": 1772400700000, "created_at": 1772400700000, "updated_at": 1772400700000},
    {"id": "d2r", "business_id": "biz-d", "entry_type": "sale", "amount_ngwee": -2000, "description": "",
     "payment_method": "cash", "predicted_category": null, "category_confidence": null,
     "final_category": "sales_goods", "model_version": null, "anomaly_score": null, "anomaly_flag": 0,
     "anomaly_reviewed_at": null, "reverses_id": "d2",
     "occurred_at": 1772400700000, "created_at": 1772400800000, "updated_at": 1772400800000},
    {"id": "d3", "business_id": "biz-d", "entry_type": "expense", "amount_ngwee": 30000,
     "description": "Kapenta from Mpulungu", "payment_method": "mobile_money", "predicted_category": null,
     "category_confidence": null, "final_category": "stock", "model_version": null,
     "anomaly_score": 0.97, "anomaly_flag": 1, "anomaly_reviewed_at": null, "reverses_id": null,
     "occurred_at": 1772404200000, "created_at": 1772404200000, "updated_at": 1772404200000}],
  "entry_item": [
    {"id": "di1", "entry_id": "d1", "product_id": "pd", "quantity": 2, "unit_price_ngwee": 2500},
    {"id": "di3", "entry_id": "d3", "product_id": "pd", "quantity": 5, "unit_price_ngwee": 6000}],
  "stock_adjustment": [{"id": "da1", "product_id": "pd", "quantity_delta": 10, "reason": "opening",
                        "created_at": 1772400000000}]
}$j$::jsonb);

-- ------------------------------------------------ who can read (UC12, NFR6)
select pg_temp.check((select count(*) from public.ledger_entry) = 0,
  'dashboard: a phone (signed in, not a researcher) reads no entries');
select pg_temp.check((select count(*) from public.dash_participant) = 0,
  'dashboard: a phone reads no participant summary (views keep RLS)');
select pg_temp.check(not public.is_researcher(), 'dashboard: a phone is not a researcher');
select pg_temp.expect_error($$insert into public.researcher (user_id)
  values ('00000000-0000-0000-0000-0000000000d1')$$, 'row-level security');

select pg_temp.as_anon();
select pg_temp.expect_error($$select count(*) from public.dash_participant$$, 'permission denied');
select pg_temp.check((select count(*) from public.business) = 0, 'dashboard: anon reads no businesses');

select pg_temp.as_user('00000000-0000-0000-0000-0000000000ee');
select pg_temp.check(public.is_researcher(), 'dashboard: the researcher is recognised');
select pg_temp.check((select count(*) from public.business) = 2,
  'dashboard: the researcher reads every participant (B and D)');
-- No update or delete policy: RLS matches no rows, so nothing changes.
update public.ledger_entry set amount_ngwee = 1 where id = 'd1';
delete from public.ledger_entry where id = 'd1';
select pg_temp.check((select count(*) from public.ledger_entry where id = 'd1' and amount_ngwee = 5000) = 1,
  'dashboard: read-only, an update or delete by the researcher changes nothing');
select pg_temp.expect_error($$select public.sync_push('{}'::jsonb)$$, 'no participant code claimed');

-- ---------------------------------------------------------- the numbers
select pg_temp.check(
  (select (entries, cancelled, in_ngwee, out_ngwee, flagged)
     from public.dash_participant where participant_code = 'LSK03')
  = (3::bigint, 1::bigint, 5000::bigint, 30000::bigint, 1::bigint),
  'summary: 3 entries, 1 cancelled, in K50 (the cancelled K20 nets out), out K300, 1 flagged');
select pg_temp.check(
  (select withdrawn_at is not null and business_id is null
     from public.dash_participant where participant_code = 'LSK01'),
  'summary: a withdrawn code shows as withdrawn, with no data');
select pg_temp.check(
  (select count(*) from public.dash_participant)
  = (select count(*) from public.participant_code),
  'summary: one row per participant code');

select pg_temp.check(
  (select array_agg((day, in_ngwee, out_ngwee) order by day)::text
     from public.dash_daily where business_id = 'biz-d')
  = '{"(2026-03-01,5000,0)","(2026-03-02,0,30000)"}',
  'daily: split by Lusaka day (22:30 UTC is the next day in Lusaka)');
select pg_temp.check(
  (select (amount_ngwee, entries) from public.dash_category
    where business_id = 'biz-d' and category = 'sales_goods') = (5000::bigint, 2::bigint),
  'category: sales net of the cancellation');
select pg_temp.check(
  (select stock_qty from public.dash_stock where product_id = 'pd') = 13,
  'stock: 10 opening + 5 bought - 2 sold = 13, as on the phone');

select pg_temp.as_admin();
