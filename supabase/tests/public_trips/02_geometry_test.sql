begin;
select tests.seed();
do $$
declare result jsonb; line extensions.geometry; start_point extensions.geography; end_point extensions.geography;
begin
  result := public_trip_private.sanitize_route('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',500,500);
  line := extensions.st_geomfromgeojson((result->'route')::text);
  start_point := extensions.st_setsrid(extensions.st_makepoint(36,-1),4326)::extensions.geography;
  end_point := extensions.st_setsrid(extensions.st_makepoint(36.04,-1),4326)::extensions.geography;
  perform tests.assert(not extensions.st_dwithin(line::extensions.geography,start_point,500),'all output edges clear start zone');
  perform tests.assert(not extensions.st_dwithin(line::extensions.geography,end_point,500),'all output edges clear end zone');
  perform tests.assert(jsonb_array_length(result->'counties') = 1,'counties derive from output geometry');
  perform tests.assert(extensions.st_npoints(line) < 81,'route simplified');
  perform tests.expect_error($q$select public_trip_private.sanitize_route('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',499,500)$q$,
    '22023','Trim distances');
  perform tests.expect_error($q$select public_trip_private.sanitize_route('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',null,500)$q$,
    '22023','Trim distances');
  perform tests.expect_error($q$select public_trip_private.sanitize_route('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',50000,50000)$q$,
    '22023','Not enough route');
end $$;

-- A trip that returns past its original start in the middle cannot leak it.
update public.journey_points set longitude = 36 + 0.001 * case
  when sequence_number <= 20 then sequence_number
  when sequence_number <= 40 then 40-sequence_number else sequence_number-40 end;
do $$
declare result jsonb; line extensions.geometry;
begin
  result := public_trip_private.sanitize_route('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',500,500);
  line := extensions.st_geomfromgeojson((result->'route')::text);
  perform tests.assert(jsonb_array_length(result#>'{route,coordinates}') >= 2,'return near home splits route');
  perform tests.assert(not extensions.st_dwithin(line::extensions.geography,
    extensions.st_setsrid(extensions.st_makepoint(36,-1),4326)::extensions.geography,500),
    'mid-route return is also excluded');
end $$;

-- A recording pause must remain a gap, including after simplification.
update public.journey_points set longitude = 36 + sequence_number*0.0005,
  segment_number = case when sequence_number < 40 then 0 else 1 end;
do $$
declare result jsonb;
begin
  result := public_trip_private.sanitize_route('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',500,500);
  perform tests.assert(jsonb_array_length(result#>'{route,coordinates}') = 2,'recording segments never joined');
end $$;
update public.journey_points set accuracy_m = 500 where sequence_number = 20;
select tests.expect_error($q$select public_trip_private.sanitize_route('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',500,500)$q$,
  '22023','location review');
update public.journey_points set accuracy_m = 8;
-- One GPS spike no longer rejects the trip: its two implausible steps are
-- treated as a break, and no edge is ever drawn to the bad fix.
update public.journey_points set longitude = 38 where sequence_number = 20;
do $$
declare result jsonb; line extensions.geometry;
begin
  result := public_trip_private.sanitize_route('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',500,500);
  line := extensions.st_geomfromgeojson((result->'route')::text);
  perform tests.assert(extensions.st_xmax(line) < 37,'spike point never reaches the public route');
  perform tests.assert(jsonb_array_length(result#>'{route,coordinates}') >= 2,'spike becomes a break, not a bridge');
end $$;
-- A stale first fix far from the real start is ignored and the start is still hidden.
update public.journey_points set longitude = 36 + sequence_number*0.0005;
update public.journey_points set longitude = 36.5 where sequence_number = 0;
do $$
declare result jsonb; line extensions.geometry;
begin
  result := public_trip_private.sanitize_route('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',500,500);
  line := extensions.st_geomfromgeojson((result->'route')::text);
  perform tests.assert(extensions.st_xmax(line) < 36.5,'stale first fix is not published');
  perform tests.assert(not extensions.st_dwithin(line::extensions.geography,
    extensions.st_setsrid(extensions.st_makepoint(36.0005,-1),4326)::extensions.geography,500),
    'real start is still hidden after a stale first fix');
end $$;
-- More than 10% implausible steps is too noisy to publish.
update public.journey_points set longitude = 36 + sequence_number*0.0005;
update public.journey_points set longitude = 38 where sequence_number % 5 = 2;
select tests.expect_error($q$select public_trip_private.sanitize_route('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',500,500)$q$,
  '22023','too much GPS noise');
-- Time or segment numbers running backwards are corrupt and still rejected.
update public.journey_points set longitude = 36 + sequence_number*0.0005;
update public.journey_points set recorded_at = recorded_at - interval '1 hour' where sequence_number = 30;
select tests.expect_error($q$select public_trip_private.sanitize_route('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',500,500)$q$,
  '22023','discontinuities');

-- Verify vertex limits fail closed instead of escalating simplification tolerance.
delete from public.journey_points;
insert into public.journey_points(journey_id,sequence_number,segment_number,recorded_at,latitude,longitude,accuracy_m)
  select 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',i,0,now()-interval '1 day'+i*interval '10 seconds',
    -1+(i%2)*0.0004,36+i*0.00002,8 from generate_series(0,3500) i;
select tests.expect_error($q$select public_trip_private.sanitize_route('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',500,500)$q$,
  '22023','privacy validation');
delete from public.journey_points where sequence_number > 0;
select tests.expect_error($q$select public_trip_private.sanitize_route('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',500,500)$q$,
  '22023','route size');
rollback;
