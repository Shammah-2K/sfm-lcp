-- The parts of Supabase the migration relies on, for testing in plain
-- PostgreSQL. Not used on the real project.
--
--   * roles anon, authenticated, service_role
--   * auth.users and auth.uid(), which reads the caller's id the way
--     Supabase does (from the request's JWT claims)
--   * Supabase's default privileges: every new table and function in
--     public is granted to anon and authenticated. This is why the migration
--     turns RLS on and revokes EXECUTE; the tests check that it does.
create role anon nologin;
create role authenticated nologin;
create role service_role nologin bypassrls;

create schema auth;
create table auth.users (id uuid primary key);

create function auth.uid() returns uuid language sql stable as $$
  select nullif(current_setting('request.jwt.claim.sub', true), '')::uuid
$$;

grant usage on schema auth to anon, authenticated, service_role;
grant execute on function auth.uid() to anon, authenticated, service_role;
grant usage on schema public to anon, authenticated, service_role;

alter default privileges in schema public
  grant all on tables to anon, authenticated, service_role;
alter default privileges in schema public
  grant all on sequences to anon, authenticated, service_role;
alter default privileges in schema public
  grant execute on functions to anon, authenticated, service_role;
