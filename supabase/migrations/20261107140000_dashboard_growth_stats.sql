-- Additive RPC: the original no-argument dashboard RPC remains compatible.
create or replace function public.dashboard_growth_stats(
  p_start timestamptz default null,
  p_end timestamptz default null,
  p_leaderboard_period boolean default false
) returns jsonb
language plpgsql stable security definer set search_path = ''
as $$
declare
  v_end timestamptz := least(coalesce(p_end, now()), now());
  v_start timestamptz;
  v_prev timestamptz;
  v_users uuid[];
  v_result jsonb;
begin
  if coalesce(public.current_admin_role() in ('owner','admin'),false) is not true then
    raise exception 'Owner or admin access required' using errcode='42501';
  end if;
  select coalesce(array_agg(u.user_id), '{}'::uuid[]) into v_users
  from public.search_users_dashboard('') u
  where u.dashboard_visibility = 'visible' and not u.is_automated_test_account;
  select coalesce(p_start, least(min(created_at), v_end - interval '1 second'))
    into v_start from public.profiles where id = any(v_users);
  if not isfinite(v_start) or not isfinite(v_end) or v_start >= v_end then
    raise exception 'Invalid reporting dates' using errcode='22023';
  end if;
  v_prev := v_start - (v_end - v_start);

  with
  -- Historical activity uses durable journeys/county events only. Device
  -- last_seen is useful for observed activity but is not an event history.
  durable as materialized (
    select user_id, started_at as at from public.journeys where user_id=any(v_users) and started_at<v_end
    union all
    select user_id, entered_at from public.county_visit_events
      where user_id=any(v_users) and source<>'dev_seed' and entered_at<v_end
  ),
  activity as materialized (
    select * from durable
    union all
    select user_id,last_seen_at from public.push_devices where user_id=any(v_users) and last_seen_at<v_end
  ),
  cohort as materialized (
    select p.*, (exists(select 1 from public.county_visit_events e where e.user_id=p.id and e.source<>'dev_seed' and e.entered_at>=p.created_at and e.entered_at<v_end)
      or exists(select 1 from public.journeys j where j.user_id=p.id and j.ended_at>=p.created_at and j.ended_at<v_end)) as activated
    from public.profiles p where p.id=any(v_users) and p.created_at>=v_start and p.created_at<v_end
  ),
  trips as materialized (
    select j.*, extract(epoch from j.ended_at-j.started_at)/60 as minutes,
      exists(select 1 from public.journey_points pt where pt.journey_id=j.id and pt.segment_number>0) as has_break
    from public.journeys j where j.user_id=any(v_users) and j.ended_at>=v_prev and j.ended_at<v_end
  ),
  entries as materialized (
    select * from public.county_visit_events where user_id=any(v_users)
      and source<>'dev_seed' and entered_at>=v_prev and entered_at<v_end
  ),
  latest as (
    select distinct on(platform) platform,version from public.app_version_releases
    where status='live' and channel='production'
    order by platform,major desc,minor desc,patch desc,build desc nulls last
  ),
  phones as (
    select distinct on(user_id) user_id,platform,nullif(split_part(coalesce(app_version,''),'+',1),'') as version
    from public.push_devices where user_id=any(v_users) and last_seen_at>=v_start and last_seen_at<v_end
    order by user_id,last_seen_at desc,id
  ),
  -- Include legacy confirmed county records as well as durable events. Group
  -- before ranking so repeat passes and explored upgrades never double count.
  evidence as (
    select user_id,county_id,entered_at as at,outcome='explored' as explored
    from public.county_visit_events where user_id=any(v_users) and source<>'dev_seed'
      and outcome in ('explored','passed_through') and entered_at<v_end
    union all
    select user_id,county_id,entered_at,state='explored' from public.county_visits
    where user_id=any(v_users) and state in ('explored','passed_through') and entered_at<v_end
      and not exists(select 1 from public.county_visit_events e
        where e.user_id=county_visits.user_id and e.county_id=county_visits.county_id and e.source<>'dev_seed')
      and not exists(select 1 from public.county_visit_events e
        where e.user_id=county_visits.user_id and e.county_id=county_visits.county_id and e.source='dev_seed')
  ),
  coverage as (
    select user_id,county_id,min(at) as first_at,bool_or(explored) as explored
    from evidence group by user_id,county_id
  ),
  leaders as (
    select c.user_id,count(*) as total,count(*) filter(where c.explored) as explored,
      count(*) filter(where not c.explored) as passed_through,max(c.first_at) as achieved_at
    from coverage c join public.profiles p on p.id=c.user_id
    where p.show_on_leaderboards and (not p_leaderboard_period or c.first_at>=v_start)
    group by c.user_id
  ),
  ranked as (
    select row_number() over(order by l.total desc,l.explored desc,l.achieved_at,l.user_id) as rank,l.*,
      coalesce(nullif(q.handle,''),nullif(q.display_name,''),'Traveller') as name
    from leaders l left join public.quest_public_profiles q on q.user_id=l.user_id
    order by l.total desc,l.explored desc,l.achieved_at,l.user_id limit 20
  ),
  invited as (
    select w.id,min(i.sent_at) as invited_at,w.user_id,w.email_key
    from public.waitlist_signups w join public.beta_tester_invites i on i.signup_id=w.id
    where i.sent_at is not null group by w.id,w.user_id,w.email_key
  ),
  converted as (
    select i.id,p.id as user_id,(exists(select 1 from public.county_visit_events e where e.user_id=p.id and e.source<>'dev_seed' and e.entered_at>=i.invited_at and e.entered_at<v_end)
      or exists(select 1 from public.journeys j where j.user_id=p.id and j.ended_at>=i.invited_at and j.ended_at<v_end)) as activated
    from invited i left join auth.users u on
      (u.id=i.user_id or (i.user_id is null and lower(btrim(u.email))=i.email_key))
      and u.created_at>=i.invited_at and u.created_at<v_end and u.id=any(v_users)
    left join public.profiles p on p.id=u.id
    where i.invited_at>=v_start and i.invited_at<v_end
  )
  select jsonb_build_object(
    'generated_at',now(),
    'period',jsonb_build_object('start',v_start,'end',v_end,'comparable',p_start is not null),
    'active',jsonb_build_object(
      'this_week',(select count(distinct user_id) from activity where at>=v_start),
      'previous_week',(select count(distinct user_id) from activity where at>=v_prev and at<v_start),
      'last_30_days',(select count(distinct user_id) from activity where at>=v_end-interval '30 days')
    ),
    'trips',jsonb_build_object(
      'this_week',(select count(*) from trips where ended_at>=v_start),
      'previous_week',(select count(*) from trips where ended_at<v_start),
      'people_this_week',(select count(distinct user_id) from trips where ended_at>=v_start),
      'distance_km_this_week',(select round(coalesce(sum(distance_m),0)/1000.0,1) from trips where ended_at>=v_start),
      'median_minutes_this_week',(select round((percentile_cont(0.5) within group(order by minutes))::numeric) from trips where ended_at>=v_start),
      'with_breaks_this_week',(select count(*) from trips where ended_at>=v_start and has_break),
      'with_breaks_previous_week',(select count(*) from trips where ended_at<v_start and has_break)
    ),
    'counties',jsonb_build_object(
      'this_week',(select count(*) from entries where entered_at>=v_start),
      'previous_week',(select count(*) from entries where entered_at<v_start),
      'people_this_week',(select count(distinct user_id) from entries where entered_at>=v_start),
      'explored_this_week',(select count(*) from entries where entered_at>=v_start and outcome='explored'),
      'automatic_this_week',(select count(*) from entries where entered_at>=v_start and source='automatic')
    ),
    'versions',(select jsonb_build_object('people',count(*),
      'known_version',count(*) filter(where p.version is not null and l.version is not null),
      'on_latest',count(*) filter(where p.version=l.version),
      'latest',(select coalesce(jsonb_object_agg(platform,version),'{}'::jsonb) from latest))
      from phones p left join latest l on l.platform=p.platform),
    'new_users',(select jsonb_build_object('signed_up',count(*),
      'set_home_county',count(*) filter(where home_county_id is not null),
      'first_county',count(*) filter(where exists(select 1 from public.county_visit_events e where e.user_id=c.id and e.source<>'dev_seed' and e.entered_at>=c.created_at and e.entered_at<v_end)),
      'first_trip',count(*) filter(where exists(select 1 from public.journeys j where j.user_id=c.id and j.ended_at>=c.created_at and j.ended_at<v_end))) from cohort c),
    'feedback',(select jsonb_build_object(
      'open',count(*) filter(where status in ('received','triaged','investigating','planned')),
      'open_blocking',count(*) filter(where status in ('received','triaged','investigating','planned') and severity='blocking'),
      'waiting_reply',count(*) filter(where status in ('received','triaged','investigating','planned') and responded_at is null),
      'median_reply_hours_30_days',round((percentile_cont(0.5) within group(order by extract(epoch from responded_at-created_at)/3600.0)
        filter(where created_at>=v_start and created_at<v_end and responded_at is not null and responded_at<v_end))::numeric,1)) from public.feedback_reports),
    'pro',jsonb_build_object(
      'pro_now',(select count(distinct user_id) from public.pro_entitlement_periods where user_id=any(v_users) and starts_at<=now() and (ends_at is null or ends_at>now())),
      'pro_new_this_week',(select count(distinct user_id) from public.pro_entitlement_periods where user_id=any(v_users) and starts_at>=v_start and starts_at<v_end),
      'trial_users_this_month',(select count(*) from public.journey_trial_usage where user_id=any(v_users) and period_month=date_trunc('month',now() at time zone 'UTC')::date and trips_used>0),
      'trial_at_limit_this_month',(select count(*) from public.journey_trial_usage where user_id=any(v_users) and period_month=date_trunc('month',now() at time zone 'UTC')::date and trips_used>=3)
    ),
    'growth',jsonb_build_object(
      'previous_signups',(select count(*) from public.profiles where id=any(v_users) and created_at>=v_prev and created_at<v_start),
      'activated',(select count(*) from cohort where activated),
      'new_active',(select count(distinct a.user_id) from activity a join public.profiles p on p.id=a.user_id where a.at>=v_start and p.created_at>=v_start),
      'returning_active',(select count(distinct a.user_id) from activity a join public.profiles p on p.id=a.user_id where a.at>=v_start and p.created_at<v_start),
      'weekly_active',(select count(distinct user_id) from activity where at>=v_end-interval '7 days'),
      'monthly_active',(select count(distinct user_id) from activity where at>=v_end-interval '30 days'),
      'retention_7_eligible',(select count(*) from cohort where created_at+interval '14 days'<=v_end),
      'retention_7_returned',(select count(*) from cohort c where created_at+interval '14 days'<=v_end and exists(select 1 from durable d where d.user_id=c.id and d.at>=c.created_at+interval '7 days' and d.at<c.created_at+interval '14 days')),
      'retention_30_eligible',(select count(*) from cohort where created_at+interval '37 days'<=v_end),
      'retention_30_returned',(select count(*) from cohort c where created_at+interval '37 days'<=v_end and exists(select 1 from durable d where d.user_id=c.id and d.at>=c.created_at+interval '30 days' and d.at<c.created_at+interval '37 days')),
      'invited',(select count(*) from converted),
      'registered',(select count(*) from converted where user_id is not null),
      'invite_activated',(select count(*) from converted where activated)
    ),
    'leaderboard',(select coalesce(jsonb_agg(to_jsonb(r) order by rank),'[]'::jsonb) from ranked r)
  ) into v_result;
  return v_result;
end;
$$;
revoke all on function public.dashboard_growth_stats(timestamptz,timestamptz,boolean) from public,anon;
grant execute on function public.dashboard_growth_stats(timestamptz,timestamptz,boolean) to authenticated;
