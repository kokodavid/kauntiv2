-- Trip quality: compare Trips recorded with battery saver on and off.
--
-- Adds battery_saver to the per-Trip view (from the settings snapshot the app
-- sends at Trip start) and one admin-only function that groups by it.
-- battery_saver is null for Trips recorded before the snapshot existed.

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
  (q.summary #>> '{settings,battery_saver}')::boolean as battery_saver
from public.journey_quality q
join public.journeys j on j.id = q.journey_id;

revoke all on public.journey_quality_trips from anon, authenticated;

create or replace function public.journey_quality_by_power_saving(p_days integer default 90)
returns table (
  battery_saver boolean,
  trips bigint,
  system_pauses bigint,
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
    t.battery_saver,
    count(*)::bigint,
    sum(t.system_pauses)::bigint,
    round(sum(t.lost_ms) / sum(t.duration_ms), 4)
  from public.journey_quality_trips t
  where t.started_at >= now() - make_interval(days => least(greatest(coalesce(p_days, 90), 1), 365))
  group by t.battery_saver
  order by t.battery_saver nulls last;
end;
$$;

revoke all on function public.journey_quality_by_power_saving(integer) from public, anon;
grant execute on function public.journey_quality_by_power_saving(integer) to authenticated;
