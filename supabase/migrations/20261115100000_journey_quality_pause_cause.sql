-- Trip quality: what the phone's power settings looked like at the moment a
-- location-lost pause happened, not just at Trip start.
--
-- settings_at_pause is only present on trips where the app re-read the
-- phone's settings right before a locationLost pause (added alongside this
-- migration). Adds those fields to the per-trip view, plus whether battery
-- saver flipped on mid-trip (clean at start, on by the time it paused), and
-- one admin-only function bucketing locationLost pauses by their most likely
-- cause, in the same priority the app itself uses to word the in-app note:
-- battery saver first, then low battery, then background-app restriction on
-- makers known to enforce it.

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
  coalesce((q.summary ->> 'stream_losses')::int, 0) as stream_losses,
  (q.summary #>> '{settings,battery_saver}')::boolean as battery_saver,
  coalesce((q.summary #>> '{pauses,location_lost}')::int, 0) as location_lost_pauses,
  (q.summary #>> '{settings_at_pause,battery_saver}')::boolean as battery_saver_at_pause,
  (q.summary #>> '{settings_at_pause,battery_optimised}')::boolean as battery_optimised_at_pause,
  (q.summary #>> '{settings_at_pause,battery_percent}')::int as battery_percent_at_pause,
  coalesce((q.summary #>> '{settings_at_pause,strict_maker}')::boolean, false) as strict_maker_at_pause,
  coalesce((q.summary #>> '{settings_at_pause,battery_saver}')::boolean, false)
    and not coalesce((q.summary #>> '{settings,battery_saver}')::boolean, false)
    as battery_saver_turned_on_mid_trip
from public.journey_quality q
join public.journeys j on j.id = q.journey_id;

revoke all on public.journey_quality_trips from anon, authenticated;

-- Among trips with at least one locationLost pause, which cause the phone's
-- own settings pointed to right when it happened. Mirrors the priority
-- JourneyDeviceSettings.warnings uses app-side: battery saver, then low
-- battery (below JourneyDeviceSettings.lowBatteryPercent, 15%), then battery
-- optimisation on a maker known to enforce it -- otherwise "unexplained",
-- meaning the settings we could read do not account for the loss.
create or replace function public.journey_quality_pause_cause_overview(p_days integer default 90)
returns table (
  cause text,
  trips bigint,
  turned_on_mid_trip_trips bigint,
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
  with lost as (
    select
      t.*,
      case
        when t.battery_saver_at_pause then 'battery_saver'
        when t.battery_percent_at_pause is not null and t.battery_percent_at_pause < 15
          then 'low_battery'
        when t.battery_optimised_at_pause and t.strict_maker_at_pause
          then 'battery_optimisation'
        else 'unexplained'
      end as cause
    from public.journey_quality_trips t
    where t.location_lost_pauses > 0
      and t.started_at >= now() - make_interval(days => least(greatest(coalesce(p_days, 90), 1), 365))
  )
  select
    l.cause,
    count(*)::bigint,
    sum(l.battery_saver_turned_on_mid_trip::int)::bigint,
    round(sum(l.lost_ms) / sum(l.duration_ms), 4)
  from lost l
  group by l.cause
  order by count(*) desc;
end;
$$;

revoke all on function public.journey_quality_pause_cause_overview(integer) from public, anon;
grant execute on function public.journey_quality_pause_cause_overview(integer) to authenticated;
