-- Radius-aware Side Quests discovery. The user's saved preference defaults to
-- 100 km and is constrained to the five values exposed by the Flutter UI.
alter table public.profiles
  add column if not exists side_quest_radius_km integer not null default 100
    check (side_quest_radius_km in (25, 50, 100, 250, 500));

-- The new location parameters change the function signature. Drop the
-- previous overload so calls that only pass p_limit remain unambiguous.
drop function if exists public.side_quests_feed(integer);

create function public.side_quests_feed(
  p_limit integer default 20,
  p_latitude double precision default null,
  p_longitude double precision default null,
  p_radius_km integer default null
)
returns table (
  quest_id uuid,
  publisher_kind text,
  publisher_name text,
  publisher_handle text,
  publisher_avatar_url text,
  quest_kind text,
  title text,
  summary text,
  visibility text,
  join_policy text,
  schedule_type text,
  starts_at timestamptz,
  ends_at timestamptz,
  joined_count bigint,
  max_participants integer,
  viewer_membership_status text,
  is_owner boolean,
  cover_image_url text,
  distance_m double precision
)
language sql
stable
security invoker
as $$
  with visited_current_county as (
    select c.centroid
    from public.county_visits v
    join public.counties c on c.id = v.county_id
    where v.user_id = auth.uid()
    order by v.entered_at desc
    limit 1
  ),
  current_location as (
    select extensions.ST_SetSRID(
             extensions.ST_MakePoint(p_longitude, p_latitude), 4326
           ) as point
    where p_latitude is not null and p_longitude is not null

    union all

    select centroid from visited_current_county
    where p_latitude is null or p_longitude is null

    union all

    select c.centroid
    from public.profiles profile
    join public.counties c on c.id = profile.home_county_id
    where profile.id = auth.uid()
      and profile.home_county_id is not null
      and (p_latitude is null or p_longitude is null)
      and not exists (select 1 from visited_current_county)
    limit 1
  ),
  selected_radius as (
    select coalesce(
      p_radius_km,
      (select profile.side_quest_radius_km
       from public.profiles profile where profile.id = auth.uid()),
      100
    )::double precision as km
  ),
  quest_distances as (
    select
      item.quest_id,
      min(extensions.ST_DistanceSphere(
        current_location.point,
        coalesce(place.location, county.centroid)
      )) as distance_m
    from public.quest_items item
    left join public.places place on place.id = item.place_id
    left join public.counties county on county.id = item.county_id
    cross join current_location
    where coalesce(place.location, county.centroid) is not null
    group by item.quest_id
  )
  select
    quest.id,
    quest.publisher_kind,
    coalesce(profile.display_name, quest.publisher_name, 'Kaunti47'),
    profile.handle,
    profile.avatar_url,
    quest.quest_kind,
    quest.title,
    quest.summary,
    quest.visibility,
    quest.join_policy,
    quest.schedule_type,
    quest.starts_at,
    quest.ends_at,
    public.quest_joined_count(quest.id),
    quest.max_participants,
    (select member.membership_status from public.quest_members member
      where member.quest_id = quest.id and member.user_id = auth.uid()),
    quest.created_by = auth.uid(),
    quest.cover_image_url,
    distances.distance_m
  from public.quests quest
  join quest_distances distances on distances.quest_id = quest.id
  cross join selected_radius radius
  left join public.quest_public_profiles profile on profile.user_id = quest.created_by
  where quest.status = 'published'
    and quest.moderation_status = 'approved'
    and (quest.ends_at is null or quest.ends_at >= now())
    and distances.distance_m <= radius.km * 1000
  order by distances.distance_m, quest.starts_at asc nulls last, quest.published_at desc
  limit least(greatest(p_limit, 1), 50);
$$;

revoke execute on function public.side_quests_feed(
  integer,
  double precision,
  double precision,
  integer
) from public;
grant execute on function public.side_quests_feed(
  integer,
  double precision,
  double precision,
  integer
) to authenticated;
