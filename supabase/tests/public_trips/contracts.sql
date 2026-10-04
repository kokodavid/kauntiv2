-- Contracts consumed by these additive migrations. Production definitions live
-- in 20260902144307, 20260904020000, 20260911100000, 20260914150000, 20260925160000,
-- 20260930110000, 20261001020000, 20261002090000, 20261003100000.
alter table public.journeys add column transport_mode text;
grant select,delete on public.journeys to authenticated;
grant select on public.journey_points to authenticated;
alter table public.journey_points add column altitude_m numeric, add column speed_mps numeric;
create table public.journey_media(id uuid primary key default gen_random_uuid(),
  journey_id uuid not null references public.journeys(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  storage_path text not null unique, captured_at timestamptz not null,
  latitude double precision, longitude double precision);
create table public.quest_public_profiles(user_id uuid primary key references auth.users(id) on delete cascade,
  display_name text not null, handle text not null unique, avatar_url text);
create table public.pro_entitlement_periods(user_id uuid not null references auth.users(id) on delete cascade,
  starts_at timestamptz not null, ends_at timestamptz);
create function public.has_pro_at(p_user_id uuid, p_at timestamptz) returns boolean
language sql stable security definer set search_path = public as $$
  select exists (select 1 from public.pro_entitlement_periods period where period.user_id = p_user_id
    and period.starts_at <= p_at and (period.ends_at is null or period.ends_at > p_at));
$$;
revoke execute on function public.has_pro_at(uuid,timestamptz) from public;
create table public.admin_members(user_id uuid primary key references auth.users(id),
  role text,status text,county_scope smallint[]);
create table public.user_moderation_status(user_id uuid primary key references auth.users(id),status text);
create table public.app_feature_flags(feature_key text primary key
  check (feature_key in ('county_news')),enabled boolean,updated_at timestamptz,updated_by uuid);
create table public.counties(id smallint primary key,name text,
  geometry extensions.geometry(MultiPolygon,4326),centroid extensions.geometry(Point,4326));
create table public.county_visits(user_id uuid,county_id smallint,state text);

create function tests.seed() returns void language plpgsql as $$
begin
  insert into auth.users(id,email) select tests.actor(n),n || '@example.invalid'
    from unnest(array['owner','viewer','admin','outsider','other']) n;
  insert into public.admin_members values (tests.actor('admin'),'admin','active',null);
  insert into public.counties values (47,'Test County',
    extensions.st_multi(extensions.st_makeenvelope(35,-2,37,0,4326)),
    extensions.st_setsrid(extensions.st_makepoint(36,-1),4326));
  insert into public.journeys(id,user_id,title,started_at,ended_at,distance_m,transport_mode)
    values ('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',tests.actor('owner'),'PRIVATE SOURCE TITLE',
      now()-interval '30 minutes',now()-interval '10 minutes',999999,'drive');
  insert into public.journey_points(journey_id,sequence_number,segment_number,recorded_at,latitude,longitude,
      accuracy_m,altitude_m,speed_mps)
    select 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',i,0,
      now()-interval '30 minutes'+i*interval '10 seconds',-1,36+i*0.0005,8,1600+i,5.5 from generate_series(0,80) i;
  insert into public.quest_public_profiles values
    (tests.actor('owner'),'Test Owner','test-owner','https://example.invalid/avatar.png');
  -- One photo mid-route (public) and one beside the start (inside the hidden zone).
  insert into public.journey_media(id,journey_id,user_id,storage_path,captured_at) values
    ('f1111111-1111-4111-8111-111111111111','aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',tests.actor('owner'),
      'owner/aaaa/f1.jpg',now()-interval '30 minutes'+40*interval '10 seconds'),
    ('f2222222-2222-4222-8222-222222222222','aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',tests.actor('owner'),
      'owner/aaaa/f2.jpg',now()-interval '30 minutes'+2*interval '10 seconds');
end $$;

create function tests.enable() returns void language plpgsql as $$
begin
  perform tests.login('admin');
  insert into public.pro_entitlement_periods(user_id,starts_at) values (tests.actor('owner'),now()-interval '1 day');
  perform public.set_public_trip_flags_dashboard(true,true);
end $$;

-- Only fixtures call seed/enable as postgres; never grant these setup helpers.
revoke execute on function tests.seed(),tests.enable() from public,authenticated,anon;
