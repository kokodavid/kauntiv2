-- How well each Trip recorded, for the team's quality view.
--
-- The app sends a small summary of counts after a Trip uploads: pauses by
-- reason, gaps, dropped spikes, location-stream losses, plus app version and
-- phone model. No coordinates and no places. Only admins can read it, and the
-- overview functions below return aggregates and Trip ids, never user ids.

create table if not exists public.journey_quality (
  journey_id uuid primary key references public.journeys (id) on delete cascade,
  user_id uuid not null references auth.users (id) on delete cascade,
  summary jsonb not null check (jsonb_typeof(summary) = 'object'),
  app_version text,
  platform text,
  os_version text,
  device_model text,
  created_at timestamptz not null default now()
);

alter table public.journey_quality enable row level security;

revoke all on public.journey_quality from anon, authenticated;
grant select on public.journey_quality to authenticated;

drop policy if exists journey_quality_admin_read on public.journey_quality;
create policy journey_quality_admin_read
  on public.journey_quality
  for select
  to authenticated
  using (public.is_admin());

create or replace function public.save_journey_quality(
  p_journey_id uuid,
  p_summary jsonb,
  p_app_version text default null,
  p_platform text default null,
  p_os_version text default null,
  p_device_model text default null
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user uuid := auth.uid();
begin
  if v_user is null then
    raise exception 'Sign in to save Trip quality' using errcode = '42501';
  end if;
  if p_summary is null or jsonb_typeof(p_summary) <> 'object'
     or length(p_summary::text) > 2000 then
    raise exception 'Trip quality summary is not valid' using errcode = '22023';
  end if;
  if not exists (
    select 1 from public.journeys
    where id = p_journey_id and user_id = v_user
  ) then
    raise exception 'Trip not found for this account' using errcode = '42501';
  end if;

  insert into public.journey_quality as q (
    journey_id, user_id, summary, app_version, platform, os_version, device_model
  )
  values (
    p_journey_id, v_user, p_summary,
    left(p_app_version, 40), left(p_platform, 20),
    left(p_os_version, 80), left(p_device_model, 80)
  )
  on conflict (journey_id) do update
    set summary = excluded.summary,
        app_version = excluded.app_version,
        platform = excluded.platform,
        os_version = excluded.os_version,
        device_model = excluded.device_model;
end;
$$;

revoke all on function public.save_journey_quality(uuid, jsonb, text, text, text, text) from public, anon;
grant execute on function public.save_journey_quality(uuid, jsonb, text, text, text, text) to authenticated;

-- Per-Trip numbers used by both overview functions.
create or replace view public.journey_quality_trips
with (security_invoker = true) as
select
  q.journey_id,
  j.started_at,
  q.platform,
  q.os_version,
  q.app_version,
  q.device_model,
  greatest(extract(epoch from (j.ended_at - j.started_at)) * 1000, 1) as duration_ms,
  coalesce((q.summary ->> 'gap_ms')::numeric, 0)
    + coalesce((q.summary ->> 'lost_ms')::numeric, 0) as lost_ms,
  coalesce((q.summary #>> '{pauses,location_lost}')::int, 0)
    + coalesce((q.summary #>> '{pauses,app_restarted}')::int, 0)
    + coalesce((q.summary #>> '{pauses,start_failed}')::int, 0)
    + coalesce((q.summary #>> '{pauses,account_changed}')::int, 0) as system_pauses,
  coalesce((q.summary ->> 'spikes_dropped')::int, 0) as spikes_dropped,
  coalesce((q.summary ->> 'stream_losses')::int, 0) as stream_losses
from public.journey_quality q
join public.journeys j on j.id = q.journey_id;

revoke all on public.journey_quality_trips from anon, authenticated;

create or replace function public.journey_quality_overview(p_days integer default 90)
returns table (
  platform text,
  os_version text,
  app_version text,
  device_model text,
  trips bigint,
  system_pauses bigint,
  spikes_dropped bigint,
  stream_losses bigint,
  lost_share numeric
)
language plpgsql
stable
security definer
set search_path = public
as $$
begin
  if not public.has_admin_role('viewer'::public.admin_role) then
    raise exception 'Trip quality is for admins' using errcode = '42501';
  end if;
  return query
  select
    t.platform, t.os_version, t.app_version, t.device_model,
    count(*)::bigint,
    sum(t.system_pauses)::bigint,
    sum(t.spikes_dropped)::bigint,
    sum(t.stream_losses)::bigint,
    round(sum(t.lost_ms) / sum(t.duration_ms), 4)
  from public.journey_quality_trips t
  where t.started_at >= now() - make_interval(days => least(greatest(coalesce(p_days, 90), 1), 365))
  group by t.platform, t.os_version, t.app_version, t.device_model
  order by count(*) desc
  limit 200;
end;
$$;

create or replace function public.journey_quality_worst(p_limit integer default 20)
returns table (
  journey_id uuid,
  started_at timestamptz,
  platform text,
  os_version text,
  app_version text,
  device_model text,
  system_pauses integer,
  spikes_dropped integer,
  stream_losses integer,
  lost_share numeric
)
language plpgsql
stable
security definer
set search_path = public
as $$
begin
  if not public.has_admin_role('viewer'::public.admin_role) then
    raise exception 'Trip quality is for admins' using errcode = '42501';
  end if;
  return query
  select
    t.journey_id, t.started_at, t.platform, t.os_version, t.app_version,
    t.device_model, t.system_pauses, t.spikes_dropped, t.stream_losses,
    round(t.lost_ms / t.duration_ms, 4)
  from public.journey_quality_trips t
  order by t.lost_ms / t.duration_ms desc, t.system_pauses desc
  limit least(greatest(coalesce(p_limit, 20), 1), 100);
end;
$$;

revoke all on function public.journey_quality_overview(integer) from public, anon;
revoke all on function public.journey_quality_worst(integer) from public, anon;
grant execute on function public.journey_quality_overview(integer) to authenticated;
grant execute on function public.journey_quality_worst(integer) to authenticated;
