-- Entire edges are dropped at privacy boundaries, rather than interpolating
-- new points into hidden areas. Projection is local to Kenya (UTM 37S);
-- authoritative exclusion and distance checks use geodesic metres.
create function public_trip_private.sanitize_route(
  p_journey_id uuid, p_start_m integer, p_end_m integer
) returns jsonb language plpgsql security definer set search_path = '' as $$
declare
  v_count integer; v_start extensions.geography; v_end extensions.geography;
  v_route jsonb; v_geometry extensions.geometry; v_distance numeric; v_counties jsonb;
  v_retained jsonb;
begin
  if p_start_m is null or p_end_m is null or p_start_m not between 500 and 50000
    or p_end_m not between 500 and 50000 then
    raise exception 'Trim distances must be 500 to 50000 metres' using errcode = '22023';
  end if;
  select count(*) into v_count from public.journey_points where journey_id = p_journey_id;
  if v_count < 2 or v_count > 50000 then
    raise exception 'Unsupported route size' using errcode = '22023';
  end if;
  if exists (select 1 from public.journey_points where journey_id = p_journey_id
    and (latitude not between -5 and 6 or longitude not between 33 and 43
      or accuracy_m > 100 or accuracy_m < 0)) then
    raise exception 'Route needs location review' using errcode = '22023';
  end if;
  select extensions.st_setsrid(extensions.st_makepoint(longitude, latitude),4326)::extensions.geography
    into v_start from public.journey_points where journey_id = p_journey_id order by sequence_number limit 1;
  select extensions.st_setsrid(extensions.st_makepoint(longitude, latitude),4326)::extensions.geography
    into v_end from public.journey_points where journey_id = p_journey_id order by sequence_number desc limit 1;

  if exists (
    select 1 from (
      select p.*, lag(recorded_at) over w as prior_time,
        lag(segment_number) over w as prior_segment,
        lag(latitude) over w as prior_lat, lag(longitude) over w as prior_lng
      from public.journey_points p where journey_id = p_journey_id
      window w as (order by sequence_number)
    ) p where prior_time is not null and
      (recorded_at <= prior_time or segment_number < prior_segment or
        (segment_number = prior_segment and (
          extensions.st_distance(
            extensions.st_setsrid(extensions.st_makepoint(longitude, latitude),4326)::extensions.geography,
            extensions.st_setsrid(extensions.st_makepoint(prior_lng, prior_lat),4326)::extensions.geography
          ) > least(2000, 60 * extract(epoch from recorded_at - prior_time)))))
  ) then
    raise exception 'Route has discontinuities needing review' using errcode = '22023';
  end if;

  with points as (
    select sequence_number, segment_number, recorded_at,
      extensions.st_setsrid(extensions.st_makepoint(longitude, latitude),4326) as point
    from public.journey_points where journey_id = p_journey_id
  ), pairs as (
    select *, lag(point) over w as prior_point, lag(segment_number) over w as prior_segment,
      lag(sequence_number) over w as prior_sequence, lag(recorded_at) over w as prior_time
    from points window w as (order by sequence_number)
  ), edges as (
    select *, extensions.st_makeline(prior_point, point) as edge,
      case when prior_segment = segment_number and prior_sequence + 1 = sequence_number
        and recorded_at - prior_time <= interval '2 minutes'
      then extensions.st_distance(prior_point::extensions.geography, point::extensions.geography)
      else 0 end as metres
    from pairs
  ), measured as (
    select *, sum(metres) over (order by sequence_number) as travelled,
      sum(metres) over () as total from edges
  ), retained as (
    select * from measured where metres > 0
      and travelled - metres >= p_start_m and total - travelled >= p_end_m
      and not extensions.st_dwithin(edge::extensions.geography, v_start, p_start_m)
      and not extensions.st_dwithin(edge::extensions.geography, v_end, p_end_m)
  ), breaks as (
    select *, case when lag(sequence_number) over (order by sequence_number) = prior_sequence
      and lag(segment_number) over (order by sequence_number) = segment_number
      then 0 else 1 end as boundary from retained
  ), grouped as (
    select *, sum(boundary) over (order by sequence_number) as group_id from breaks
  ), lines as (
    select group_id, min(prior_sequence) as first_seq, max(sequence_number) as last_seq,
      extensions.st_makeline(edge order by sequence_number) as line
    from grouped group by group_id
  ), simplified as (
    select group_id, first_seq, last_seq, extensions.st_transform(extensions.st_simplifypreservetopology(
      extensions.st_transform(line,32737), 10),4326) as line from lines
  ) select jsonb_build_object('type', 'MultiLineString', 'coordinates',
      jsonb_agg((extensions.st_asgeojson(line,6)::jsonb)->'coordinates' order by group_id)),
      jsonb_agg(jsonb_build_array(first_seq, last_seq) order by group_id)
    into v_route, v_retained from simplified;

  if v_route->'coordinates' is null or v_route->'coordinates' = 'null'::jsonb then
    raise exception 'Not enough route remains after privacy filtering' using errcode = '22023';
  end if;
  -- Check the actual serialized geometry after simplification and rounding.
  v_geometry := extensions.st_setsrid(extensions.st_geomfromgeojson(v_route::text),4326);
  if not extensions.st_isvalid(v_geometry) or extensions.st_npoints(v_geometry) > 2000
    or extensions.st_dwithin(v_geometry::extensions.geography, v_start, p_start_m)
    or extensions.st_dwithin(v_geometry::extensions.geography, v_end, p_end_m) then
    raise exception 'Public route failed privacy validation' using errcode = '22023';
  end if;
  v_distance := round(extensions.st_length(v_geometry::extensions.geography)::numeric,2);
  if v_distance < 1000 then
    raise exception 'Public route must retain at least one kilometre' using errcode = '22023';
  end if;
  select coalesce(jsonb_agg(jsonb_build_object('code',c.id,'name',c.name) order by c.id),'[]'::jsonb)
    into v_counties from public.counties c where extensions.st_intersects(c.geometry,v_geometry);
  -- 'retained' lists the private point sequence ranges that stayed public. It
  -- is only for placing moments and photos while preparing; never stored or
  -- returned to anyone.
  return jsonb_build_object('route',v_route,'distance_m',v_distance,'counties',v_counties,
    'retained',v_retained);
end $$;
revoke all on function public_trip_private.sanitize_route(uuid,integer,integer) from public, anon, authenticated;
