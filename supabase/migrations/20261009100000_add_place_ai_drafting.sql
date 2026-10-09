-- AI place drafting: settings (switchable model), run log, dashboard RPCs,
-- and service-only helpers used by the draft-place-details edge function.

create table if not exists public.place_ai_settings (
  id boolean primary key default true check (id),
  model text not null default 'claude-haiku-5-5'
    check (model ~ '^claude-[a-z0-9.-]+$'),
  model_options jsonb not null default '[
    {"id":"claude-haiku-5-5","label":"Haiku 5.5 (cheapest, default)"},
    {"id":"claude-sonnet-5-5","label":"Sonnet 5.5 (balanced)"},
    {"id":"claude-opus-5-5","label":"Opus 5.5 (most thorough, costliest)"}
  ]'::jsonb,
  daily_limit_per_admin smallint not null default 30
    check (daily_limit_per_admin between 1 and 500),
  updated_at timestamptz not null default now(),
  updated_by uuid references auth.users (id) on delete set null
);

insert into public.place_ai_settings (id) values (true)
on conflict (id) do nothing;

create table if not exists public.place_ai_runs (
  id bigint generated always as identity primary key,
  user_id uuid references auth.users (id) on delete set null,
  query text not null,
  model text not null,
  status text not null check (status in ('ok', 'not_found', 'duplicate', 'error')),
  input_tokens integer,
  output_tokens integer,
  web_searches smallint,
  created_at timestamptz not null default now()
);

create index if not exists place_ai_runs_user_created_idx
  on public.place_ai_runs (user_id, created_at desc);

alter table public.place_ai_settings enable row level security;
alter table public.place_ai_runs enable row level security;
revoke all on public.place_ai_settings from public, anon, authenticated;
revoke all on public.place_ai_runs from public, anon, authenticated;

create or replace function public.get_place_ai_settings_dashboard()
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  s public.place_ai_settings;
  used integer;
begin
  if coalesce(
    public.current_admin_role() in ('owner', 'admin', 'editor'),
    false
  ) is not true then
    raise exception 'Dashboard access required' using errcode = '42501';
  end if;

  select * into s from public.place_ai_settings where id;
  select count(*) into used
  from public.place_ai_runs
  where user_id = auth.uid()
    and created_at >= date_trunc('day', now());

  return jsonb_build_object(
    'model', s.model,
    'model_options', s.model_options,
    'daily_limit_per_admin', s.daily_limit_per_admin,
    'used_today', used
  );
end;
$$;

create or replace function public.set_place_ai_model_dashboard(p_model text)
returns text
language plpgsql
security definer
set search_path = public
as $$
begin
  if coalesce(
    public.current_admin_role() in ('owner', 'admin'),
    false
  ) is not true then
    raise exception 'Owner or admin access required' using errcode = '42501';
  end if;

  if not exists (
    select 1
    from public.place_ai_settings s,
         jsonb_array_elements(s.model_options) o
    where o ->> 'id' = p_model
  ) then
    raise exception 'Unknown model %', p_model using errcode = '22023';
  end if;

  update public.place_ai_settings
  set model = p_model, updated_at = now(), updated_by = auth.uid()
  where id;

  return p_model;
end;
$$;

-- Service-role only helpers.
create or replace function public.place_ai_county_for_point(
  p_lat double precision,
  p_lng double precision
)
returns table (id smallint, name text)
language sql
stable
security definer
set search_path = extensions, public
as $$
  select c.id, c.name
  from public.counties c
  where st_contains(
    c.geometry,
    st_setsrid(st_makepoint(p_lng, p_lat), 4326)
  )
  limit 1;
$$;

create or replace function public.place_ai_similar_places(p_name text)
returns table (id uuid, name text, county_id smallint)
language sql
stable
security definer
set search_path = public
as $$
  select p.id, p.name, p.county_id
  from public.places p
  where length(trim(p_name)) >= 3
    and (
      p.name ilike '%' || trim(p_name) || '%'
      or trim(p_name) ilike '%' || p.name || '%'
    )
  limit 5;
$$;

revoke all on function public.get_place_ai_settings_dashboard() from public, anon;
revoke all on function public.set_place_ai_model_dashboard(text) from public, anon;
grant execute on function public.get_place_ai_settings_dashboard() to authenticated;
grant execute on function public.set_place_ai_model_dashboard(text) to authenticated;

revoke all on function public.place_ai_county_for_point(double precision, double precision)
  from public, anon, authenticated;
revoke all on function public.place_ai_similar_places(text)
  from public, anon, authenticated;
grant execute on function public.place_ai_county_for_point(double precision, double precision)
  to service_role;
grant execute on function public.place_ai_similar_places(text) to service_role;
