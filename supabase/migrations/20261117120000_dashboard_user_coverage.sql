-- Share audience rules between directory browsing and reporting. Only the
-- directory applies a page limit.
create function public.dashboard_user_candidates(v_query text, v_audience text)
returns table (
  user_id uuid,
  email text,
  display_name text,
  handle text,
  avatar_url text,
  status text,
  created_at timestamptz,
  dashboard_visibility text,
  has_meaningful_activity boolean,
  is_automated_test_account boolean
)
language sql stable set search_path = ''
as $$
  with candidates as (
    select
      auth_user.id,
      coalesce(auth_user.email::text, '') as email,
      profile.display_name,
      profile.handle,
      profile.avatar_url,
      coalesce(moderation.status, 'active') as status,
      auth_user.created_at,
      coalesce(visibility.visibility, 'visible') as dashboard_visibility,
      public.dashboard_user_has_meaningful_activity(auth_user.id) as has_meaningful_activity,
      coalesce(auth_user.email ~* '^[^@]+[.][0-9]{5}@[[:alnum:].-]+$', false) as is_automated_test_account
    from auth.users auth_user
    left join public.quest_public_profiles profile on profile.user_id = auth_user.id
    left join public.user_moderation_status moderation on moderation.user_id = auth_user.id
    left join public.dashboard_user_visibility_overrides visibility on visibility.user_id = auth_user.id
    where v_query = ''
      or auth_user.email ilike '%' || v_query || '%'
      or profile.handle ilike '%' || v_query || '%'
      or profile.display_name ilike '%' || v_query || '%'
  )
  select *
  from candidates candidate
  where case v_audience
    when 'engaged' then
      candidate.dashboard_visibility <> 'hidden'
      and candidate.has_meaningful_activity
      and not candidate.is_automated_test_account
    when 'unengaged' then
      candidate.dashboard_visibility <> 'hidden'
      and not candidate.has_meaningful_activity
      and not candidate.is_automated_test_account
    when 'automated' then
      candidate.dashboard_visibility <> 'hidden'
      and candidate.is_automated_test_account
    when 'hidden' then candidate.dashboard_visibility = 'hidden'
  end;
$$;

revoke all on function public.dashboard_user_candidates(text, text) from public, anon, authenticated;

-- Keep the existing RPC available to deployed clients and the signup preview.
create or replace function public.search_users_dashboard(
  p_query text default null,
  p_audience text default 'engaged'
)
returns table (
  user_id uuid,
  email text,
  display_name text,
  handle text,
  avatar_url text,
  status text,
  created_at timestamptz,
  dashboard_visibility text,
  has_meaningful_activity boolean,
  is_automated_test_account boolean
)
language plpgsql security definer set search_path = ''
as $$
declare
  v_audience text := lower(btrim(coalesce(p_audience, 'engaged')));
begin
  if public.can_moderate_users() is not true then
    raise exception 'Viewing users requires owner, admin, or moderator access' using errcode = '42501';
  end if;
  if v_audience not in ('engaged', 'unengaged', 'automated', 'hidden') then
    raise exception 'Unknown dashboard user audience: %', v_audience using errcode = '22023';
  end if;

  return query
  select u.*
  from public.dashboard_user_candidates(btrim(coalesce(p_query, '')), v_audience) u
  order by u.created_at desc, u.user_id desc
  limit 50;
end;
$$;

create function public.list_app_users_dashboard(
  p_query text,
  p_audience text,
  p_filter text,
  p_offset bigint
)
returns table (
  user_id uuid,
  email text,
  display_name text,
  handle text,
  avatar_url text,
  status text,
  created_at timestamptz,
  dashboard_visibility text,
  has_meaningful_activity boolean,
  is_automated_test_account boolean,
  has_premium boolean
)
language plpgsql stable security definer set search_path = ''
as $$
declare
  v_role public.admin_role := public.current_admin_role();
  v_can_see_premium boolean := coalesce(v_role in ('owner', 'admin'), false);
begin
  if coalesce(v_role in ('owner', 'admin', 'moderator'), false) is not true then
    raise exception 'Viewing users requires owner, admin, or moderator access' using errcode = '42501';
  end if;
  if p_audience is null or p_audience not in ('engaged', 'unengaged', 'automated', 'hidden')
     or p_filter is null or p_filter not in ('all', 'active', 'suspended', 'premium')
     or p_offset is null or p_offset < 0 then
    raise exception 'Invalid app users filters or offset' using errcode = '22023';
  end if;
  if p_filter = 'premium' and not v_can_see_premium then
    raise exception 'Viewing Premium access requires owner or admin access' using errcode = '42501';
  end if;

  return query
  with matched as (
    select u.*,
      case when v_can_see_premium then exists (
        select 1
        from public.pro_entitlement_periods e
        where e.user_id = u.user_id
          and e.starts_at <= now()
          and (e.ends_at is null or e.ends_at > now())
      ) else false end as has_premium
    from public.dashboard_user_candidates(btrim(coalesce(p_query, '')), p_audience) u
  )
  select m.*
  from matched m
  where case p_filter
    when 'all' then true
    when 'premium' then m.has_premium
    else m.status = p_filter
  end
  order by m.created_at desc, m.user_id desc
  limit 51 offset p_offset; -- One extra row indicates that another page exists.
end;
$$;

revoke all on function public.list_app_users_dashboard(text, text, text, bigint) from public, anon, authenticated;
grant execute on function public.list_app_users_dashboard(text, text, text, bigint) to authenticated;

create or replace function public.dashboard_metric_users()
returns uuid[]
language sql stable security definer set search_path = ''
as $$
  select coalesce(array_agg(u.user_id), '{}'::uuid[])
  from public.dashboard_user_candidates('', 'engaged') u;
$$;

revoke all on function public.dashboard_metric_users() from public, anon, authenticated;

-- Leaderboard analysis: how people compare. Names only for people who allow
-- leaderboards; aggregate panels count everyone; groups under 5 are hidden.
create or replace function public.dashboard_leaderboard_analysis(
  p_start timestamptz default null,
  p_end timestamptz default null
) returns jsonb
language plpgsql volatile security definer set search_path = ''
as $$
declare
  v_end timestamptz := least(coalesce(p_end, now()), now());
  v_start timestamptz;
  v_users uuid[];
  v_result jsonb;
begin
  if coalesce(public.current_admin_role() in ('owner', 'admin'), false) is not true then
    raise exception 'Owner or admin access required' using errcode = '42501';
  end if;
  v_users := public.dashboard_metric_users();
  select coalesce(p_start, least(min(p.created_at), v_end - interval '1 second'))
    into v_start from public.profiles p where p.id = any(v_users);
  v_start := coalesce(v_start, v_end - interval '30 days');
  if not isfinite(v_start) or not isfinite(v_end) or v_start >= v_end then
    raise exception 'Invalid reporting dates' using errcode = '22023';
  end if;

  create temp table if not exists dl_trips on commit drop as
    select * from public.dashboard_metric_trips(v_users, v_end) limit 0;
  truncate dl_trips;
  insert into dl_trips select * from public.dashboard_metric_trips(v_users, v_end);

  create temp table if not exists dl_coverage on commit drop as
    select * from public.dashboard_metric_coverage(v_users, v_end) limit 0;
  truncate dl_coverage;
  insert into dl_coverage select * from public.dashboard_metric_coverage(v_users, v_end);

  create temp table if not exists dl_travel on commit drop as
    select a.user_id, a.at from public.dashboard_metric_actions(v_users, v_end) a limit 0;
  truncate dl_travel;
  insert into dl_travel select a.user_id, a.at from public.dashboard_metric_actions(v_users, v_end) a where a.kind = 'travel';

  create temp table if not exists dl_people (
    user_id uuid primary key, shown boolean, name text, home_county text, pro boolean, state text,
    total integer, explored integer, new_in_period integer, real_trips integer, notable_trips integer,
    best_score integer, total_km numeric, longest_km numeric, travel_days integer, streak_months integer
  ) on commit drop;
  truncate dl_people;

  insert into dl_people
  with months as (
    select distinct t.user_id, date_trunc('month', t.ended_at at time zone 'Africa/Nairobi')::date as m
    from dl_trips t
  ),
  anchored as (
    -- A streak counts back from this month, or last month if this one is still empty.
    select m.user_id, m.m,
      (extract(year from age(date_trunc('month', v_end at time zone 'Africa/Nairobi')::date, m.m)) * 12
        + extract(month from age(date_trunc('month', v_end at time zone 'Africa/Nairobi')::date, m.m)))::integer as back,
      row_number() over (partition by m.user_id order by m.m desc) - 1 as idx
    from months m
  ),
  streaks as (
    select a.user_id, count(*)::integer as months
    from anchored a
    where a.back - a.idx = (select min(b.back) from anchored b where b.user_id = a.user_id)
      and (select min(b.back) from anchored b where b.user_id = a.user_id) <= 1
    group by a.user_id
  )
  select p.id,
    coalesce(p.show_on_leaderboards, true),
    public.dashboard_metric_name(p.id),
    c.name,
    exists (select 1 from public.pro_entitlement_periods e
      where e.user_id = p.id and e.starts_at <= now() and (e.ends_at is null or e.ends_at > now())),
    s.state,
    (select count(*)::integer from dl_coverage cv where cv.user_id = p.id),
    (select count(*)::integer from dl_coverage cv where cv.user_id = p.id and cv.explored),
    (select count(*)::integer from dl_coverage cv where cv.user_id = p.id and cv.first_at >= v_start),
    (select count(*)::integer from dl_trips t where t.user_id = p.id and t.ended_at >= v_start),
    (select count(*)::integer from dl_trips t where t.user_id = p.id and t.ended_at >= v_start and t.notable),
    (select max(t.score) from dl_trips t where t.user_id = p.id and t.ended_at >= v_start),
    (select round(coalesce(sum(t.distance_m), 0) / 1000.0, 1) from dl_trips t where t.user_id = p.id and t.ended_at >= v_start),
    (select round(max(t.distance_m) / 1000.0, 1) from dl_trips t where t.user_id = p.id and t.ended_at >= v_start),
    (select count(distinct (tr.at at time zone 'Africa/Nairobi')::date)::integer from dl_travel tr
      where tr.user_id = p.id and tr.at >= v_start),
    coalesce((select st.months from streaks st where st.user_id = p.id), 0)
  from public.profiles p
  left join public.counties c on c.id = p.home_county_id
  left join public.dashboard_metric_states(v_users) s on s.user_id = p.id
  where p.id = any(v_users);

  with
  board as (
    select row_number() over (order by d.total desc, d.explored desc, d.user_id) as rank, d.*
    from dl_people d where d.shown and d.total > 3
  ),
  by_notable as (
    select b.*, lead(b.user_id) over (order by b.notable_trips desc, b.rank) as next_id
    from board b where b.notable_trips > 0
  ),
  races as (
    select a.name as a_name, b.name as b_name, a.total as a_value, b.total as b_value,
      'counties' as measure, a.rank as sort_key
    from board a join board b on b.rank = a.rank + 1
    where a.total - b.total <= 1
    union all
    select a.name, b.name, a.notable_trips, b.notable_trips, 'notable_trips', 1000 + a.rank
    from by_notable a join board b on b.user_id = a.next_id
    where a.notable_trips - b.notable_trips <= 1
  ),
  holders as (
    select cv.county_id, count(*) as people from dl_coverage cv group by cv.county_id
  ),
  board_cov as (
    select cv.user_id, cv.county_id from dl_coverage cv join board b on b.user_id = cv.user_id
  ),
  pairs as (
    select x.user_id as a, y.user_id as b, count(*) as shared
    from board_cov x join board_cov y on y.county_id = x.county_id and y.user_id > x.user_id
    group by x.user_id, y.user_id
  ),
  homes as (
    select d.home_county, count(*) as people,
      (select t.name from dl_people t where t.home_county = d.home_county and t.shown and t.total > 0
        order by t.total desc, t.explored desc, t.user_id limit 1) as top_name
    from dl_people d where d.home_county is not null group by d.home_county
  ),
  prev30 as (select distinct t.user_id from dl_travel t where t.at >= v_end - interval '60 days' and t.at < v_end - interval '30 days'),
  cur as (select distinct t.user_id from dl_travel t where t.at >= v_end - interval '30 days'),
  back as (
    select (b.user_id is not null) as leader, count(*) as base, count(c.user_id) as returned
    from prev30 p
    left join board b on b.user_id = p.user_id
    left join cur c on c.user_id = p.user_id
    group by (b.user_id is not null)
  )
  select jsonb_build_object(
    'generated_at', now(),
    'period', jsonb_build_object('start', v_start, 'end', v_end, 'comparable', p_start is not null),
    'people', (select count(*) from dl_people),
    'spread', (select jsonb_build_object(
      'none', count(*) filter (where d.total = 0),
      'one_to_three', count(*) filter (where d.total between 1 and 3),
      'four_to_nine', count(*) filter (where d.total between 4 and 9),
      'ten_to_nineteen', count(*) filter (where d.total between 10 and 19),
      'twenty_to_46', count(*) filter (where d.total between 20 and 46),
      'all_47', count(*) filter (where d.total >= 47)
    ) from dl_people d),
    'close_races', (select coalesce(jsonb_agg(to_jsonb(r) order by r.sort_key), '[]'::jsonb) from (
      select * from races order by sort_key limit 10) r),
    'home_groups', (select coalesce(jsonb_agg(jsonb_build_object(
        'county', h.home_county,
        'people', case when h.people >= 5 then h.people end,
        'top_name', case when h.people >= 5 then h.top_name end
      ) order by h.people desc, h.home_county), '[]'::jsonb)
      from (select * from homes order by people desc, home_county limit 10) h),
    'shared', jsonb_build_object(
      'most_held', (select coalesce(jsonb_agg(jsonb_build_object('county', c.name, 'people', h.people)
          order by h.people desc, c.name), '[]'::jsonb)
        from (select * from holders order by people desc, county_id limit 5) h
        join public.counties c on c.id = h.county_id),
      'rarest', (select coalesce(jsonb_agg(jsonb_build_object('county', c.name, 'people', h.people)
          order by h.people, c.name), '[]'::jsonb)
        from (select * from holders order by people, county_id limit 5) h
        join public.counties c on c.id = h.county_id),
      'nobody_yet', (select count(*) from public.counties c where not exists (select 1 from holders h where h.county_id = c.id)),
      'pairs', (select coalesce(jsonb_agg(jsonb_build_object(
          'a_name', public.dashboard_metric_name(pr.a), 'b_name', public.dashboard_metric_name(pr.b), 'shared', pr.shared)
          order by pr.shared desc), '[]'::jsonb)
        from (select * from pairs order by shared desc, a, b limit 5) pr)
    ),
    'leaders_vs_everyone', jsonb_build_object(
      'comparable', exists (select 1 from dl_travel t where t.at < v_end - interval '60 days'),
      'leaders_base', coalesce((select base from back where leader), 0),
      'leaders_returned', coalesce((select returned from back where leader), 0),
      'others_base', coalesce((select base from back where not leader), 0),
      'others_returned', coalesce((select returned from back where not leader), 0)
    ),
    'table', (select coalesce(jsonb_agg(jsonb_build_object(
        'rank', b.rank, 'user_id', b.user_id, 'name', b.name, 'home_county', b.home_county,
        'pro', b.pro, 'state', b.state, 'total', b.total, 'explored', b.explored,
        'passed_through', b.total - b.explored, 'new_in_period', b.new_in_period,
        'real_trips', b.real_trips, 'notable_trips', b.notable_trips, 'best_score', b.best_score,
        'total_km', b.total_km, 'longest_km', b.longest_km, 'travel_days', b.travel_days,
        'streak_months', b.streak_months
      ) order by b.rank), '[]'::jsonb)
      from board b),
    'eligible', (select count(*) from board)
  ) into v_result;
  return v_result;
end;
$$;

revoke all on function public.dashboard_leaderboard_analysis(timestamptz, timestamptz) from public, anon;
grant execute on function public.dashboard_leaderboard_analysis(timestamptz, timestamptz) to authenticated;
