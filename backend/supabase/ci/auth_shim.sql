-- The Supabase-only objects our migrations reference, recreated on plain
-- Postgres so CI can apply the real migration files unchanged. Not applied
-- to Supabase itself, which already has all of these.

create schema if not exists auth;

create table if not exists auth.users (
  id uuid primary key
);

-- Supabase's auth.uid(): the signed-in user's id from the request JWT.
create or replace function auth.uid() returns uuid
language sql stable as $$
  select nullif(current_setting('request.jwt.claim.sub', true), '')::uuid
$$;

do $$
begin
  if not exists (select 1 from pg_roles where rolname = 'authenticated') then
    create role authenticated nologin;
  end if;
  if not exists (select 1 from pg_roles where rolname = 'anon') then
    create role anon nologin;
  end if;
end $$;
