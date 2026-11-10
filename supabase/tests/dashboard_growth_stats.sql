-- Isolated PGlite fixture schema; never execute this file against a live DB.
create role anon;
create role authenticated;
create schema auth;
create table auth.users(id uuid primary key,email text,created_at timestamptz);
create table public.profiles(id uuid primary key,created_at timestamptz,home_county_id smallint,show_on_leaderboards boolean default true,hidden boolean default false,automated boolean default false);
create table public.quest_public_profiles(user_id uuid,handle text,display_name text);
create table public.journeys(id uuid,user_id uuid,started_at timestamptz,ended_at timestamptz,distance_m numeric);
create table public.journey_points(journey_id uuid,segment_number integer);
create table public.county_visit_events(user_id uuid,county_id smallint,entered_at timestamptz,outcome text,source text);
create table public.county_visits(user_id uuid,county_id smallint,entered_at timestamptz,state text);
create table public.push_devices(id uuid,user_id uuid,platform text,app_version text,last_seen_at timestamptz);
create table public.app_version_releases(platform text,version text,status text,channel text,major integer,minor integer,patch integer,build integer);
create table public.feedback_reports(status text,severity text,responded_at timestamptz,created_at timestamptz);
create table public.pro_entitlement_periods(user_id uuid,starts_at timestamptz,ends_at timestamptz);
create table public.journey_trial_usage(user_id uuid,period_month date,trips_used integer);
create table public.waitlist_signups(id uuid,user_id uuid,email_key text);
create table public.beta_tester_invites(signup_id uuid,sent_at timestamptz);
create function public.current_admin_role() returns text language sql as $$ select nullif(current_setting('test.role',true),'') $$;
create function public.search_users_dashboard(text) returns table(user_id uuid,dashboard_visibility text,is_automated_test_account boolean)
language sql as $$ select id,case when hidden then 'hidden' else 'visible' end,automated from public.profiles $$;

insert into public.profiles(id,created_at) values
 ('00000000-0000-0000-0000-000000000001',now()-interval '50 days'),
 ('00000000-0000-0000-0000-000000000002',now()-interval '50 days'),
 ('00000000-0000-0000-0000-000000000003',now()-interval '50 days'),
 ('00000000-0000-0000-0000-000000000004',now()-interval '40 days'),
 ('00000000-0000-0000-0000-000000000005',now()-interval '250 days');
update public.profiles set hidden=true where id='00000000-0000-0000-0000-000000000003';
update public.profiles set show_on_leaderboards=false where id='00000000-0000-0000-0000-000000000004';
insert into auth.users select id,id::text||'@example.test',created_at from public.profiles;
insert into public.county_visit_events values
 ('00000000-0000-0000-0000-000000000001',1,now()-interval '40 days','passed_through','automatic'),
 ('00000000-0000-0000-0000-000000000001',1,now()-interval '5 days','explored','automatic'),
 ('00000000-0000-0000-0000-000000000001',2,now()-interval '4 days','passed_through','automatic'),
 ('00000000-0000-0000-0000-000000000001',3,now()-interval '3 days','passed_through','automatic'),
 ('00000000-0000-0000-0000-000000000001',3,now()-interval '2 days','passed_through','automatic'),
 ('00000000-0000-0000-0000-000000000001',4,now()-interval '1 day','explored','dev_seed'),
 ('00000000-0000-0000-0000-000000000002',1,now()-interval '10 days','explored','automatic'),
 ('00000000-0000-0000-0000-000000000002',2,now()-interval '7 days','explored','automatic'),
 ('00000000-0000-0000-0000-000000000002',3,now()-interval '1 day','passed_through','automatic'),
 ('00000000-0000-0000-0000-000000000003',1,now()-interval '1 day','explored','automatic'),
 ('00000000-0000-0000-0000-000000000004',1,now()-interval '32 days','explored','automatic'),
 ('00000000-0000-0000-0000-000000000004',2,now()-interval '8 days','explored','automatic'),
 -- Older coverage lifts users 1 and 2 above the 3-county leaderboard minimum.
 ('00000000-0000-0000-0000-000000000001',10,now()-interval '90 days','passed_through','automatic'),
 ('00000000-0000-0000-0000-000000000001',11,now()-interval '90 days','passed_through','automatic'),
 ('00000000-0000-0000-0000-000000000001',12,now()-interval '90 days','passed_through','automatic'),
 ('00000000-0000-0000-0000-000000000002',10,now()-interval '80 days','passed_through','automatic'),
 ('00000000-0000-0000-0000-000000000002',11,now()-interval '80 days','passed_through','automatic'),
 ('00000000-0000-0000-0000-000000000002',12,now()-interval '30 days','passed_through','automatic'),
 -- User 5 has exactly 3 counties, so never appears on the leaderboard.
 ('00000000-0000-0000-0000-000000000005',20,now()-interval '90 days','explored','automatic'),
 ('00000000-0000-0000-0000-000000000005',21,now()-interval '90 days','explored','automatic'),
 ('00000000-0000-0000-0000-000000000005',22,now()-interval '90 days','explored','automatic');
-- Legacy duplicate and seeded fallback must not increase coverage.
insert into public.county_visits values
 ('00000000-0000-0000-0000-000000000001',1,now()-interval '40 days','explored'),
 ('00000000-0000-0000-0000-000000000001',4,now()-interval '1 day','explored');
