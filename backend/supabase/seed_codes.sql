-- The researcher-issued participant codes (decision D6, 27 Oct 2026).
-- Run once in the Supabase SQL editor after the migration. Codes only: which
-- person holds which code stays on the paper consent records.
--
-- To add a code later (e.g. a phone set up with a code not on this list):
--   insert into public.participant_code (code) values ('ABC123');
-- To let a new phone use a code (lost phone, reinstall):
--   select public.release_code('LSK05');
insert into public.participant_code (code)
select 'LSK' || lpad(n::text, 2, '0') from generate_series(1, 20) as n
on conflict (code) do nothing;
