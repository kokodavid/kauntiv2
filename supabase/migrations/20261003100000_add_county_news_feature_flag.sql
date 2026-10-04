create table if not exists public.app_feature_flags (
  feature_key text primary key
    check (feature_key in ('county_news')),
  enabled boolean not null default false,
  updated_at timestamptz not null default now(),
  updated_by uuid references auth.users (id) on delete set null
);

alter table public.app_feature_flags enable row level security;

drop policy if exists "Public can read app feature flags"
  on public.app_feature_flags;
create policy "Public can read app feature flags"
  on public.app_feature_flags
  for select
  to anon, authenticated
  using (true);

revoke all on public.app_feature_flags from public, anon, authenticated;
grant select on public.app_feature_flags to anon, authenticated;

insert into public.app_feature_flags (feature_key, enabled)
values ('county_news', true)
on conflict (feature_key) do nothing;

create or replace function public.set_county_news_enabled_dashboard(
  p_enabled boolean
)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
begin
  if coalesce(
    public.current_admin_role() in ('owner', 'admin'),
    false
  ) is not true then
    raise exception 'Owner or admin access required'
      using errcode = '42501';
  end if;
  if p_enabled is null then
    raise exception 'Enabled value is required'
      using errcode = '22004';
  end if;

  insert into public.app_feature_flags (
    feature_key,
    enabled,
    updated_at,
    updated_by
  ) values (
    'county_news',
    p_enabled,
    now(),
    auth.uid()
  )
  on conflict (feature_key) do update
  set enabled = excluded.enabled,
      updated_at = excluded.updated_at,
      updated_by = excluded.updated_by;

  return p_enabled;
end;
$$;

revoke execute on function public.set_county_news_enabled_dashboard(boolean)
  from public, anon;
grant execute on function public.set_county_news_enabled_dashboard(boolean)
  to authenticated;
