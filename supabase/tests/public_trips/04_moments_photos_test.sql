begin;
select tests.seed();
select tests.enable();
create table tests.state(name text primary key, value jsonb);
grant all on tests.state to authenticated, service_role;

-- Share defaults, moment/photo placement and hidden-area exclusion.
set local role authenticated;
do $$
declare prefs jsonb; candidate jsonb; pub uuid; rev integer;
begin
  perform tests.login('owner');
  prefs := public.get_public_trip_share_preferences();
  perform tests.assert(prefs->>'county_crossing' = 'true' and prefs->>'elevation_peak' = 'true'
    and prefs->>'top_speed' = 'false' and prefs->>'long_stop' = 'false'
    and prefs->>'photos' = 'false' and (prefs->>'trim_m')::int = 500,'default share preferences');
  prefs := public.set_public_trip_share_preferences(true,true,true,false,false,true,1000);
  perform tests.assert(prefs->>'top_speed' = 'true' and (prefs->>'trim_m')::int = 1000,'preferences saved');
  perform tests.expect_error('select public.set_public_trip_share_preferences(true,true,true,false,false,true,750)','22023');

  perform tests.expect_error($q$select public.prepare_public_trip('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
    gen_random_uuid(),'Bad','[{"kind":"teleport","sequence_number":40}]'::jsonb)$q$,'22023','Moments');
  perform tests.expect_error(format($q$select public.prepare_public_trip('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
    gen_random_uuid(),'Bad','[]'::jsonb,array[%L]::uuid[])$q$,gen_random_uuid()),'22023','Photo unavailable');

  candidate := public.prepare_public_trip('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',gen_random_uuid(),'With moments',
    '[{"kind":"top_speed","sequence_number":40},{"kind":"county_crossing","sequence_number":41},
      {"kind":"long_stop","sequence_number":1}]'::jsonb,
    array['f1111111-1111-4111-8111-111111111111','f2222222-2222-4222-8222-222222222222']::uuid[]);
  pub := (candidate->>'id')::uuid; rev := (candidate->>'revision')::integer;
  perform tests.assert(jsonb_array_length(candidate->'moments') = 2,'moments on the public route kept');
  perform tests.assert(candidate#>>'{excluded,moments,0,sequence_number}' = '1','hidden-area moment excluded');
  perform tests.assert(candidate#>'{excluded,photo_ids}' = '["f2222222-2222-4222-8222-222222222222"]'::jsonb,
    'hidden-area photo excluded');
  perform tests.assert(jsonb_array_length(candidate->'photos') = 0 and (candidate->>'photos_pending')::int = 1,
    'photo waits for sanitizing');
  perform tests.assert(candidate->>'trip_date' =
    to_char((now()-interval '30 minutes') at time zone 'Africa/Nairobi','YYYY-MM-DD'),'trip date published');
  perform tests.assert(candidate#>>'{author,handle}' = 'test-owner'
    and candidate#>>'{author,avatar_url}' is not null,'author identity from public profile');
  perform tests.expect_error(format('select public.submit_public_trip(%L,%s,%L,%L)',
    pub,rev,candidate->>'content_hash','public-trips-v1'),'55000');
  perform tests.expect_error('select public.list_public_trip_photo_jobs()','42501');
  insert into tests.state values ('candidate',candidate);
end $$;
reset role;

-- The worker completes the photo; a stale generation is refused.
set local role service_role;
do $$
declare jobs jsonb;
begin
  jobs := public.list_public_trip_photo_jobs();
  perform tests.assert(jsonb_array_length(jobs) = 1 and jobs#>>'{0,source_path}' = 'owner/aaaa/f1.jpg',
    'worker sees the pending photo');
  perform tests.assert(not public.complete_public_trip_photo((jobs#>>'{0,id}')::uuid,
    (jobs#>>'{0,generation}')::int+1,'stale/photo.jpg',800,600),'stale generation refused');
  perform tests.assert(public.complete_public_trip_photo((jobs#>>'{0,id}')::uuid,
    (jobs#>>'{0,generation}')::int,'pub/photo.jpg',800,600),'worker completes the photo');
end $$;
reset role;

-- Submit, approve and read as another signed-in user.
set local role authenticated;
do $$
declare candidate jsonb := (select value from tests.state where name = 'candidate');
  shown jsonb; pub uuid; rev integer;
begin
  pub := (candidate->>'id')::uuid; rev := (candidate->>'revision')::integer;
  perform tests.login('owner');
  candidate := public.submit_public_trip(pub,rev,candidate->>'content_hash','public-trips-v1');
  perform tests.login('admin');
  perform public.review_public_trip(pub,rev,candidate->>'content_hash','approve');
  perform tests.login('outsider');
  shown := public.get_public_trip(pub);
  perform tests.assert(shown#>>'{moments,0,kind}' = 'top_speed'
    and (shown#>>'{moments,0,value,speed_mps}')::numeric = 5.5,'top speed value from server points');
  perform tests.assert(shown#>>'{moments,1,value,name}' = 'Test County','county crossing named server-side');
  perform tests.assert(jsonb_array_length(shown->'photos') = 1
    and (shown#>>'{photos,0,width}')::int = 800,'sanitized photo visible');
  perform tests.assert(position('storage_path' in shown::text) = 0 and position('sanitized_path' in shown::text) = 0
    and position('owner/aaaa' in shown::text) = 0 and position('pub/photo.jpg' in shown::text) = 0
    and position('sequence_number' in shown::text) = 0 and position('excluded' in shown::text) = 0
    and position('f1111111' in shown::text) = 0,'no storage paths, source IDs or private point IDs');
  perform tests.assert(shown#>>'{author,display_name}' = 'Test Owner','author shown to viewers');
  perform tests.assert(jsonb_array_length(public.public_trips_for_you(47::smallint)) = 1,'Home row lists the trip');
  insert into tests.state values ('pub',to_jsonb(pub));
end $$;
reset role;

-- Moderation suspension of a viewer, and deleting the source photo.
insert into public.user_moderation_status values (tests.actor('outsider'),'suspended');
delete from public.journey_media where id = 'f1111111-1111-4111-8111-111111111111';
set local role authenticated;
do $$
declare pub uuid := (select (value#>>'{}')::uuid from tests.state where name = 'pub');
begin
  perform tests.login('outsider');
  perform tests.expect_error(format('select public.get_public_trip(%L)',pub),'42501');
  perform tests.login('viewer');
  perform tests.assert(jsonb_array_length(public.get_public_trip(pub)->'photos') = 0,
    'deleting the source photo removes its public copy');
end $$;
reset role;
rollback;
