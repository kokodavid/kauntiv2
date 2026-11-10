-- Weekly growth series for the admin dashboard Overview (Usage tab).
-- Twelve rolling 7-day buckets ending at the period end, oldest first.
-- Each bucket: week_start (UTC date), value (null when nothing to divide by),
-- n (people or Trips behind the point), k (numerator on percentage charts),
-- incomplete (the window has not closed yet).
-- Same people and definitions as dashboard_overview_metrics: hidden, automated
-- test and dev-seeded accounts are left out; the team's own accounts count.
-- Never started is the same set as the "never_started" person state.

create or replace function public.dashboard_growth_series(p_end timestamptz default null)
returns jsonb
language plpgsql volatile security definer set search_path = ''
as $$
declare
  v_end timestamptz := least(coalesce(p_end, now()), now());
  v_users uuid[];
  v_data_start timestamptz;
  v_first_travel timestamptz;
  v_result jsonb;
begin
  if coalesce(public.current_admin_role() in ('owner', 'admin'), false) is not true then
    raise exception 'Owner or admin access required' using errcode = '42501';
  end if;
  if not isfinite(v_end) then
    raise exception 'Invalid reporting date' using errcode = '22023';
  end if;
  v_users := public.dashboard_metric_users();

  create temp table if not exists gs_trips on commit drop as
    select * from public.dashboard_metric_trips(v_users, v_end) limit 0;
  truncate gs_trips;
  insert into gs_trips select * from public.dashboard_metric_trips(v_users, v_end);

  create temp table if not exists gs_actions on commit drop as
    select * from public.dashboard_metric_actions(v_users, v_end) limit 0;
  truncate gs_actions;
  insert into gs_actions select * from public.dashboard_metric_actions(v_users, v_end);

  create temp table if not exists gs_states on commit drop as
    select * from public.dashboard_metric_states(v_users) limit 0;
  truncate gs_states;
  insert into gs_states select * from public.dashboard_metric_states(v_users);

  select min(p.created_at) into v_data_start from public.profiles p where p.id = any(v_users);
  select min(a.at) into v_first_travel from gs_actions a where a.kind = 'travel';

  with
  travel as (select a.user_id, a.at from gs_actions a where a.kind = 'travel'),
  weeks as (
    select k, v_end - (k * interval '7 days') as week_end,
      v_end - ((k + 1) * interval '7 days') as week_start
    from generate_series(11, 0, -1) k
  ),
  people as (
    select p.id, p.created_at from public.profiles p where p.id = any(v_users)
  ),
  travelling as (
    select wk.k, (select count(distinct t.user_id) from travel t
      where t.at >= wk.week_end - interval '30 days' and t.at < wk.week_end) as n
    from weeks wk
  ),
  signups as (
    select wk.k,
      count(c.id) as n,
      count(c.id) filter (where c.created_at <= v_end - interval '7 days') as eligible,
      count(c.id) filter (where c.created_at <= v_end - interval '7 days' and exists (
        select 1 from travel t where t.user_id = c.id
          and t.at >= c.created_at and t.at < c.created_at + interval '7 days')) as activated
    from weeks wk
    left join people c on c.created_at >= wk.week_start and c.created_at < wk.week_end
    group by wk.k
  ),
  came_back as (
    select wk.k,
      (select count(distinct t.user_id) from travel t
        where t.at >= wk.week_end - interval '60 days' and t.at < wk.week_end - interval '30 days') as base,
      (select count(distinct t.user_id) from travel t
        where t.at >= wk.week_end - interval '60 days' and t.at < wk.week_end - interval '30 days'
          and exists (select 1 from travel r where r.user_id = t.user_id
            and r.at >= wk.week_end - interval '30 days' and r.at < wk.week_end)) as returned,
      v_first_travel is not null and v_first_travel <= wk.week_end - interval '60 days' as measurable
    from weeks wk
  ),
  reliability as (
    select wk.k, count(t.journey_id) as n, count(t.journey_id) filter (where t.has_break) as broken
    from weeks wk
    left join gs_trips t on t.ended_at >= wk.week_start and t.ended_at < wk.week_end
    group by wk.k
  )
  select jsonb_build_object(
    'generated_at', now(),
    'period_end', v_end,
    'weeks_available', case when v_data_start is null then 0
      else least(12, floor(extract(epoch from v_end - v_data_start) / 604800))::integer end,
    'travelling', (select jsonb_agg(jsonb_build_object(
        'week_start', (wk.week_start at time zone 'UTC')::date, 'value', t.n, 'n', t.n, 'incomplete', false)
        order by wk.k desc)
      from weeks wk join travelling t using (k)),
    'signups', (select jsonb_agg(jsonb_build_object(
        'week_start', (wk.week_start at time zone 'UTC')::date, 'value', s.n, 'n', s.n, 'incomplete', wk.k = 0)
        order by wk.k desc)
      from weeks wk join signups s using (k)),
    'activation', (select jsonb_agg(jsonb_build_object(
        'week_start', (wk.week_start at time zone 'UTC')::date,
        'value', case when s.eligible > 0 then round(100.0 * s.activated / s.eligible)::integer end,
        'n', s.eligible, 'k', s.activated, 'incomplete', wk.k = 0)
        order by wk.k desc)
      from weeks wk join signups s using (k)),
    'came_back', (select jsonb_agg(jsonb_build_object(
        'week_start', (wk.week_start at time zone 'UTC')::date,
        'value', case when c.measurable and c.base > 0 then round(100.0 * c.returned / c.base)::integer end,
        'n', case when c.measurable then c.base else 0 end,
        'k', case when c.measurable then c.returned else 0 end,
        'incomplete', false)
        order by wk.k desc)
      from weeks wk join came_back c using (k)),
    'reliability', (select jsonb_agg(jsonb_build_object(
        'week_start', (wk.week_start at time zone 'UTC')::date,
        'value', case when r.n > 0 then round(100.0 * r.broken / r.n)::integer end,
        'n', r.n, 'k', r.broken, 'incomplete', false)
        order by wk.k desc)
      from weeks wk join reliability r using (k)),
    'never_started', (select jsonb_build_object(
      'count', count(*) filter (where s.state = 'never_started'),
      'total', count(*),
      'home_county_set', count(*) filter (where s.state = 'never_started' and p.home_county_id is not null),
      'no_home_county', count(*) filter (where s.state = 'never_started' and p.home_county_id is null)
    ) from gs_states s join public.profiles p on p.id = s.user_id)
  ) into v_result;
  return v_result;
end;
$$;

revoke all on function public.dashboard_growth_series(timestamptz) from public, anon;
grant execute on function public.dashboard_growth_series(timestamptz) to authenticated;
