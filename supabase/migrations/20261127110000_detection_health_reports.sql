-- Detection health in production (ADR 0001 decision 10, PRD requirement 12).
--
-- One row per report from a phone: how well county detection can work right
-- now (tier and reason), how long since it last heard from the OS, and
-- counts of what the safeguards did. Deliberately no coordinates, no county
-- codes and no place names: only the state of detection and the device.
--
-- Access model
--   * Phones write only through report_detection_health (security definer,
--     validates every field, caps reports per user per day). There is no
--     client insert/update/delete policy.
--   * Only admins read (public.is_admin()), through the table or the views.

create table if not exists public.detection_health_reports (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  reported_at timestamptz not null default now(),
  platform text not null check (platform in ('android', 'ios')),
  os_version text,
  manufacturer text,
  model text,
  app_version text,
  tier text not null check (tier in ('live', 'catch_up', 'off')),
  reason text not null check (
    reason in ('none', 'background_missing', 'no_permission', 'services_off')
  ),
  last_cycle_gap_s integer check (last_cycle_gap_s is null or last_cycle_gap_s >= 0),
  last_geofence_gap_s integer check (last_geofence_gap_s is null or last_geofence_gap_s >= 0),
  counts jsonb not null default '{}'::jsonb check (jsonb_typeof(counts) = 'object')
);

create index if not exists detection_health_reports_reported_at_idx
  on public.detection_health_reports (reported_at desc);
create index if not exists detection_health_reports_user_idx
  on public.detection_health_reports (user_id, reported_at desc);

alter table public.detection_health_reports enable row level security;

drop policy if exists detection_health_admin_read on public.detection_health_reports;
create policy detection_health_admin_read
  on public.detection_health_reports
  for select
  to authenticated
  using (public.is_admin());

revoke all on public.detection_health_reports from public, anon, authenticated;
grant select on public.detection_health_reports to authenticated;

create or replace function public.report_detection_health(
  p_platform text,
  p_os_version text,
  p_manufacturer text,
  p_model text,
  p_app_version text,
  p_tier text,
  p_reason text,
  p_last_cycle_gap_s integer,
  p_last_geofence_gap_s integer,
  p_counts jsonb
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
    raise exception 'not signed in' using errcode = '28000';
  end if;
  -- A phone reports about once a day and on a tier change; this only stops
  -- a buggy build from flooding the table.
  if (
    select count(*) from public.detection_health_reports r
    where r.user_id = v_user and r.reported_at > now() - interval '24 hours'
  ) >= 20 then
    return;
  end if;
  insert into public.detection_health_reports (
    user_id, platform, os_version, manufacturer, model, app_version,
    tier, reason, last_cycle_gap_s, last_geofence_gap_s, counts
  ) values (
    v_user,
    p_platform,
    left(p_os_version, 40),
    left(p_manufacturer, 60),
    left(p_model, 80),
    left(p_app_version, 40),
    p_tier,
    p_reason,
    p_last_cycle_gap_s,
    p_last_geofence_gap_s,
    case when jsonb_typeof(p_counts) = 'object' then p_counts else '{}'::jsonb end
  );
end;
$$;

revoke all on function public.report_detection_health(
  text, text, text, text, text, text, text, integer, integer, jsonb
) from public, anon;
grant execute on function public.report_detection_health(
  text, text, text, text, text, text, text, integer, integer, jsonb
) to authenticated;

-- Latest report per user in the last 7 days, grouped by platform and
-- manufacturer: "what share of Tecno users are in Off right now?".
create or replace view public.detection_health_by_device
with (security_invoker = true) as
with latest as (
  select distinct on (user_id) *
  from public.detection_health_reports
  where reported_at > now() - interval '7 days'
  order by user_id, reported_at desc
)
select
  platform,
  coalesce(nullif(manufacturer, ''), 'unknown') as manufacturer,
  count(*) as users,
  count(*) filter (where tier = 'live') as live,
  count(*) filter (where tier = 'catch_up') as catch_up,
  count(*) filter (where tier = 'off') as off,
  round(100.0 * count(*) filter (where tier = 'live') / count(*), 1) as live_pct
from latest
group by platform, coalesce(nullif(manufacturer, ''), 'unknown');

-- Why detection is below Live, by device.
create or replace view public.detection_health_reasons
with (security_invoker = true) as
with latest as (
  select distinct on (user_id) *
  from public.detection_health_reports
  where reported_at > now() - interval '7 days'
  order by user_id, reported_at desc
)
select
  platform,
  coalesce(nullif(manufacturer, ''), 'unknown') as manufacturer,
  reason,
  count(*) as users
from latest
where reason <> 'none'
group by platform, coalesce(nullif(manufacturer, ''), 'unknown'), reason;

-- Daily outcome totals from the counts column, per platform.
create or replace view public.detection_health_daily_outcomes
with (security_invoker = true) as
select
  date_trunc('day', reported_at)::date as day,
  platform,
  sum(coalesce((counts ->> 'claimed')::int, 0)) as claimed,
  sum(coalesce((counts ->> 'rejected_accuracy')::int, 0)) as rejected_accuracy,
  sum(coalesce((counts ->> 'held_border')::int, 0)) as held_border,
  sum(coalesce((counts ->> 'transit')::int, 0)) as transit
from public.detection_health_reports
group by 1, 2;

revoke all on public.detection_health_by_device from public, anon;
revoke all on public.detection_health_reasons from public, anon;
revoke all on public.detection_health_daily_outcomes from public, anon;
grant select on public.detection_health_by_device to authenticated;
grant select on public.detection_health_reasons to authenticated;
grant select on public.detection_health_daily_outcomes to authenticated;
