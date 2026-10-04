-- Minimal local Supabase contracts, not a replacement for a full migration replay.
create schema extensions;
create extension postgis with schema extensions;
create role anon nologin;
create role authenticated nologin;
create role service_role nologin bypassrls;
create schema auth;
create table auth.users(id uuid primary key,email text);
create function auth.uid() returns uuid language sql stable as $$
  select nullif(current_setting('request.jwt.claim.sub',true),'')::uuid;
$$;
grant usage on schema auth,extensions to authenticated,anon,service_role;
create schema tests;
grant usage on schema tests to authenticated,anon,service_role;
create function tests.assert(p_ok boolean,p_message text) returns void language plpgsql as $$
begin
  if p_ok is distinct from true then raise exception 'ASSERTION: %',p_message; end if;
end $$;
create function tests.expect_error(p_sql text,p_code text,p_message text default null) returns void language plpgsql as $$
begin
  begin
    execute p_sql;
  exception when others then
    if sqlstate = p_code and (p_message is null or position(p_message in sqlerrm) > 0) then return; end if;
    raise exception 'Expected %, got %: %',p_code,sqlstate,sqlerrm;
  end;
  raise exception 'Expected % but statement succeeded: %',p_code,p_sql;
end $$;
create function tests.actor(p_name text) returns uuid language sql immutable as $$
  select case p_name
    when 'owner' then '11111111-1111-4111-8111-111111111111'::uuid
    when 'viewer' then '22222222-2222-4222-8222-222222222222'::uuid
    when 'admin' then '33333333-3333-4333-8333-333333333333'::uuid
    when 'outsider' then '44444444-4444-4444-8444-444444444444'::uuid
    when 'other' then '55555555-5555-4555-8555-555555555555'::uuid end;
$$;
create function tests.login(p_name text) returns void language sql as $$
  select set_config('request.jwt.claim.sub',tests.actor(p_name)::text,true);
$$;
