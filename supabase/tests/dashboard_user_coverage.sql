-- Run with psql against a disposable, empty PostgreSQL database only.
\set ON_ERROR_STOP on
begin;

create role anon;
create role authenticated;
create schema auth;
create type public.admin_role as enum ('owner','admin','moderator','viewer');
create table auth.users(id uuid primary key,email text,created_at timestamptz not null);
create table public.profiles(id uuid primary key,created_at timestamptz,home_county_id smallint,show_on_leaderboards boolean default true);
create table public.quest_public_profiles(user_id uuid primary key,handle text,display_name text,avatar_url text);
create table public.user_moderation_status(user_id uuid primary key,status text);
create table public.dashboard_user_visibility_overrides(user_id uuid primary key,visibility text);
create table public.pro_entitlement_periods(user_id uuid,starts_at timestamptz,ends_at timestamptz);
create table public.counties(id smallint primary key,name text);
create table public.county_visit_events(user_id uuid,county_id smallint,entered_at timestamptz,outcome text,source text);
create table public.county_visits(user_id uuid,county_id smallint,entered_at timestamptz,state text);

create function public.current_admin_role() returns public.admin_role language sql as $$
  select nullif(current_setting('test.role',true),'')::public.admin_role;
$$;
create function public.can_moderate_users() returns boolean language sql as $$
  select public.current_admin_role() in ('owner','admin','moderator');
$$;
create function public.dashboard_user_has_meaningful_activity(target uuid) returns boolean language sql as $$
  select exists(select 1 from public.profiles p where p.id=target and p.home_county_id is not null);
$$;
create function public.dashboard_metric_name(target uuid) returns text language sql as $$
  select handle from public.quest_public_profiles where user_id=target;
$$;
create function public.dashboard_metric_states(uuid[]) returns table(user_id uuid,state text) language sql as $$
  select null::uuid,null::text where false;
$$;
create function public.dashboard_metric_trips(uuid[],timestamptz)
returns table(user_id uuid,ended_at timestamptz,notable boolean,score integer,distance_m numeric)
language sql as $$ select null::uuid,null::timestamptz,false,0,0::numeric where false; $$;
create function public.dashboard_metric_actions(uuid[],timestamptz)
returns table(user_id uuid,at timestamptz,kind text)
language sql as $$ select null::uuid,null::timestamptz,null::text where false; $$;

insert into auth.users select md5(n::text)::uuid,
  case n when 1 then 'older@example.test' when 211 then 'robot.12345@example.test' when 214 then null else n || '@example.test' end,
  now() - case when n=1 then interval '3 days' else interval '2 days' end
from generate_series(1,214) n;
insert into profiles select user_id,created_at,case when user_id=md5('213')::uuid then null else 1 end,
  user_id <> md5('212')::uuid from (select id as user_id,created_at from auth.users) u;
insert into counties select n, 'County '||n from generate_series(1,5) n;
insert into quest_public_profiles (user_id,handle) values (md5('1')::uuid,'older-traveller');
insert into dashboard_user_visibility_overrides values (md5('210')::uuid,'hidden');
insert into user_moderation_status values (md5('1')::uuid,'suspended');
insert into pro_entitlement_periods values (md5('1')::uuid, now() - interval '1 day', null);
insert into county_visit_events select u.id, n, now() - interval '1 day',
  case when n=1 then 'explored' else 'passed_through' end, 'automatic'
from auth.users u cross join generate_series(1,4) n
where not (u.id=md5('209')::uuid and n=4);
insert into county_visit_events values (md5('1')::uuid,5,now() - interval '1 day','explored','automatic');

create or replace function public.dashboard_metric_coverage(p_users uuid[], p_to timestamptz)
returns table (user_id uuid, county_id smallint, first_at timestamptz, explored boolean)
language sql stable security definer set search_path = ''
as $$
  with evidence as (
    select e.user_id, e.county_id, e.entered_at as at, e.outcome = 'explored' as explored
    from public.county_visit_events e
    where e.user_id = any(p_users) and e.source <> 'dev_seed'
      and e.outcome in ('explored', 'passed_through') and e.entered_at < p_to
    union all
    select v.user_id, v.county_id, v.entered_at, v.state = 'explored'
    from public.county_visits v
    where v.user_id = any(p_users) and v.state in ('explored', 'passed_through') and v.entered_at < p_to
      and not exists (
        select 1 from public.county_visit_events e
        where e.user_id = v.user_id and e.county_id = v.county_id
      )
  )
  select e.user_id, e.county_id, min(e.at), bool_or(e.explored)
  from evidence e
  group by e.user_id, e.county_id;
$$;

\ir ../migrations/20261117120000_dashboard_user_coverage.sql

set test.role = 'owner';
set role authenticated;
do $$
declare board jsonb;
begin
  if (select count(*) from public.search_users_dashboard('', 'engaged')) <> 50 then raise exception 'legacy RPC changed'; end if;
  if (select count(*) from public.list_app_users_dashboard('', 'engaged', 'all', 0)) <> 51 then raise exception 'missing next-page marker'; end if;
  if not exists(select 1 from public.list_app_users_dashboard('', 'engaged', 'all', 200) where handle='older-traveller') then raise exception 'older account absent from final page'; end if;
  if (
    select count(distinct user_id)
    from generate_series(0,200,50) as offsets(n)
      cross join lateral (select user_id from public.list_app_users_dashboard('', 'engaged', 'all', offsets.n) limit 50) u
  ) <> 211 then raise exception 'pagination skipped or duplicated accounts'; end if;
  if not exists(select 1 from public.list_app_users_dashboard('older-traveller', 'engaged', 'all', 0)) then raise exception 'search failed'; end if;
  if not exists(select 1 from public.list_app_users_dashboard('', 'engaged', 'premium', 0) where handle='older-traveller' and has_premium) then raise exception 'Premium filter failed'; end if;
  if not exists(select 1 from public.list_app_users_dashboard('', 'engaged', 'suspended', 0) where handle='older-traveller') then raise exception 'status filter failed'; end if;
  if not exists(select 1 from public.list_app_users_dashboard('', 'automated', 'all', 0) where user_id=md5('211')::uuid) then raise exception 'automated audience failed'; end if;
  if not exists(select 1 from public.list_app_users_dashboard('', 'hidden', 'all', 0) where user_id=md5('210')::uuid) then raise exception 'hidden audience failed'; end if;
  if not exists(select 1 from public.list_app_users_dashboard('', 'unengaged', 'all', 0) where user_id=md5('213')::uuid) then raise exception 'needs review audience failed'; end if;
  begin
    perform public.dashboard_metric_users();
    raise exception 'private metrics helper exposed';
  exception when insufficient_privilege then null;
  end;
  board := public.dashboard_leaderboard_analysis(null,null);
  if (board->>'people')::integer <> 211 then raise exception 'metrics still capped'; end if;
  if (board->>'eligible')::integer <> 209 or jsonb_array_length(board->'table') <> 209 then raise exception 'board is incomplete'; end if;
  if board->'table'->0->>'name' <> 'older-traveller' then raise exception 'older account missing from top rank'; end if;
  if exists(select 1 from jsonb_array_elements(board->'table') j where j->>'user_id' in (md5('209')::uuid::text,md5('210')::uuid::text,md5('211')::uuid::text,md5('212')::uuid::text,md5('213')::uuid::text)) then raise exception 'ineligible user leaked'; end if;
end;
$$;
set test.role = 'moderator';
do $$ begin
  if exists(select 1 from public.list_app_users_dashboard('older', 'engaged', 'all', 0) where has_premium) then raise exception 'moderator saw Premium'; end if;
  begin
    perform public.list_app_users_dashboard('', 'engaged', 'premium', 0);
    raise exception 'moderator received Premium results';
  exception when insufficient_privilege then null;
  end;
end $$;
set test.role = '';
do $$ begin
  begin
    perform public.list_app_users_dashboard('', 'engaged', 'all', 0);
    raise exception 'non-admin received user results';
  exception when insufficient_privilege then null;
  end;
end $$;
reset role;
select 'PASS: stable paging, filters, role checks, full cohort and leaderboard' as result;

rollback;
