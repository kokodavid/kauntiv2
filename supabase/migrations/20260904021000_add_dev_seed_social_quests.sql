-- Development fixtures for the unified editorial + community Side Quests.
--
-- Service-role only: this resolves an arbitrary auth user by email/UUID and
-- writes quests and memberships on their behalf. Run from Supabase SQL Editor:
--
--   select public.dev_seed_social_quests('kokodavid78@gmail.com');
--
-- Re-running is safe. The three community quest IDs are derived from the
-- target user's UUID, while the editorial IDs are stable global fixtures.
create or replace function public.dev_seed_social_quests(
  p_identifier text,
  p_reset boolean default true
)
returns text
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid;
  v_user auth.users%rowtype;
  v_public_food_id uuid;
  v_friends_aberdare_id uuid;
  v_public_naivasha_id uuid;
  v_editorial_coast_id constant uuid := '47000000-0000-4000-8000-000000000001';
  v_editorial_rift_id constant uuid := '47000000-0000-4000-8000-000000000002';
  v_editorial_heritage_id constant uuid := '47000000-0000-4000-8000-000000000003';
begin
  if p_identifier ~* '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$' then
    select * into v_user from auth.users where id = p_identifier::uuid;
  else
    select * into v_user from auth.users where lower(email) = lower(p_identifier);
  end if;

  v_user_id := v_user.id;
  if v_user_id is null then
    raise exception 'dev_seed_social_quests: no auth.users row for %', p_identifier;
  end if;

  insert into public.quest_public_profiles (
    user_id,
    display_name,
    handle,
    avatar_url
  ) values (
    v_user_id,
    left(coalesce(
      v_user.raw_user_meta_data ->> 'full_name',
      v_user.raw_user_meta_data ->> 'name',
      split_part(coalesce(v_user.email, 'Traveler'), '@', 1),
      'Traveler'
    ), 80),
    'user-' || left(replace(v_user_id::text, '-', ''), 8),
    coalesce(
      v_user.raw_user_meta_data ->> 'avatar_url',
      v_user.raw_user_meta_data ->> 'picture'
    )
  )
  on conflict (user_id) do update set
    display_name = excluded.display_name,
    avatar_url = coalesce(excluded.avatar_url, public.quest_public_profiles.avatar_url),
    updated_at = now();

  v_public_food_id := md5(v_user_id::text || ':quest:nairobi-food-crawl')::uuid;
  v_friends_aberdare_id := md5(v_user_id::text || ':quest:aberdare-weekend')::uuid;
  v_public_naivasha_id := md5(v_user_id::text || ':quest:naivasha-sunrise')::uuid;

  if p_reset then
    delete from public.quests
    where id in (v_public_food_id, v_friends_aberdare_id, v_public_naivasha_id);
  end if;

  delete from public.quest_items
  where quest_id in (
    v_public_food_id,
    v_friends_aberdare_id,
    v_public_naivasha_id,
    v_editorial_coast_id,
    v_editorial_rift_id,
    v_editorial_heritage_id
  );

  -- Editorial fixtures are visible to every signed-in user. The target user
  -- is also enrolled so they sort to the front of their Side Quests feed.
  insert into public.quests (
    id,
    publisher_kind,
    publisher_name,
    quest_kind,
    title,
    summary,
    cover_image_url,
    description,
    visibility,
    join_policy,
    schedule_type,
    starts_at,
    ends_at,
    timezone,
    required_count,
    status,
    moderation_status,
    published_at,
    updated_at
  ) values
    (
      v_editorial_coast_id,
      'editorial',
      'Kaunti47',
      'challenge',
      'Coast Before Christmas',
      'Visit Mombasa, Kwale and Kilifi before the festive season.',
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/f/fa/Fun_at_Shelly_Beach_Mombasa.jpg/1280px-Fun_at_Shelly_Beach_Mombasa.jpg',
      'Complete all three coastal stops and discover a different side of Kenya''s shoreline.',
      'public',
      'open',
      'fixed',
      date_trunc('day', now()),
      date_trunc('day', now()) + interval '120 days',
      'Africa/Nairobi',
      3,
      'published',
      'approved',
      now() - interval '3 days',
      now()
    ),
    (
      v_editorial_rift_id,
      'editorial',
      'Kaunti47',
      'challenge',
      'Great Rift Valley Explorer',
      'Connect three classic Rift Valley counties in one journey.',
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/c/cc/Zebra_Lake_Nakuru-close_view.jpg/1280px-Zebra_Lake_Nakuru-close_view.jpg',
      'Plan a route through Nakuru, Narok and Baringo, then complete each stop before the quest closes.',
      'public',
      'open',
      'fixed',
      date_trunc('day', now()) + interval '5 days',
      date_trunc('day', now()) + interval '90 days',
      'Africa/Nairobi',
      3,
      'published',
      'approved',
      now() - interval '2 days',
      now()
    ),
    (
      v_editorial_heritage_id,
      'editorial',
      'Kaunti47',
      'challenge',
      'Kenya Heritage Trail',
      'Visit a museum, monument or cultural centre in four counties.',
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/3/34/Traditional_dhow_sailboat_in_Lamu%2C_Kenya.jpg/1280px-Traditional_dhow_sailboat_in_Lamu%2C_Kenya.jpg',
      'Choose four heritage stops anywhere in Kenya and share what you learned with your group.',
      'public',
      'approval_required',
      'flexible',
      null,
      null,
      'Africa/Nairobi',
      4,
      'published',
      'approved',
      now() - interval '1 day',
      now()
    )
  on conflict (id) do update set
    title = excluded.title,
    summary = excluded.summary,
    cover_image_url = excluded.cover_image_url,
    description = excluded.description,
    join_policy = excluded.join_policy,
    schedule_type = excluded.schedule_type,
    starts_at = excluded.starts_at,
    ends_at = excluded.ends_at,
    required_count = excluded.required_count,
    status = 'published',
    moderation_status = 'approved',
    updated_at = now();

  insert into public.quest_items (
    quest_id,
    item_type,
    county_id,
    title,
    position
  ) values
    (v_editorial_coast_id, 'county', 1, 'Mombasa', 0),
    (v_editorial_coast_id, 'county', 2, 'Kwale', 1),
    (v_editorial_coast_id, 'county', 3, 'Kilifi', 2),
    (v_editorial_rift_id, 'county', 32, 'Nakuru', 0),
    (v_editorial_rift_id, 'county', 33, 'Narok', 1),
    (v_editorial_rift_id, 'county', 30, 'Baringo', 2),
    (v_editorial_heritage_id, 'county', 5, 'Lamu heritage stop', 0),
    (v_editorial_heritage_id, 'county', 47, 'Nairobi heritage stop', 1),
    (v_editorial_heritage_id, 'county', 1, 'Mombasa heritage stop', 2),
    (v_editorial_heritage_id, 'county', 19, 'Nyeri heritage stop', 3)
  on conflict do nothing;

  -- Community fixtures are authored by the requested account and exercise
  -- both visibility modes and both join flows.
  insert into public.quests (
    id,
    created_by,
    publisher_kind,
    quest_kind,
    title,
    summary,
    cover_image_url,
    description,
    visibility,
    join_policy,
    schedule_type,
    starts_at,
    ends_at,
    timezone,
    meeting_point,
    max_participants,
    status,
    moderation_status,
    published_at,
    updated_at
  ) values
    (
      v_public_food_id,
      v_user_id,
      'community',
      'trip',
      'Nairobi Saturday Food Crawl',
      'A public afternoon tasting local favourites around Nairobi.',
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/3/33/Gyps_rueppellii_-Nairobi_National_Park%2C_Kenya-8-4c.jpg/1280px-Gyps_rueppellii_-Nairobi_National_Park%2C_Kenya-8-4c.jpg',
      'Meet for lunch, try three independently owned spots and finish with coffee before sunset.',
      'public',
      'open',
      'fixed',
      date_trunc('day', now()) + interval '10 days' + interval '12 hours',
      date_trunc('day', now()) + interval '10 days' + interval '18 hours',
      'Africa/Nairobi',
      'Kenyatta Avenue, Nairobi',
      12,
      'published',
      'approved',
      now() - interval '6 hours',
      now()
    ),
    (
      v_friends_aberdare_id,
      v_user_id,
      'community',
      'trip',
      'Aberdare Friends Weekend',
      'A friends-only camping and waterfall weekend in Nyandarua.',
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/5/5f/Lake_Olbolosat.jpg/1280px-Lake_Olbolosat.jpg',
      'We will agree on the final weekend together, share transport and split campsite responsibilities.',
      'friends_only',
      'approval_required',
      'flexible',
      date_trunc('day', now()) + interval '21 days',
      date_trunc('day', now()) + interval '23 days',
      'Africa/Nairobi',
      'Westlands, Nairobi',
      6,
      'published',
      'approved',
      now() - interval '4 hours',
      now()
    ),
    (
      v_public_naivasha_id,
      v_user_id,
      'community',
      'trip',
      'Lake Naivasha Sunrise Drive',
      'An early public drive for sunrise, breakfast and a lakeside walk.',
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/c/cc/Zebra_Lake_Nakuru-close_view.jpg/1280px-Zebra_Lake_Nakuru-close_view.jpg',
      'Leave Nairobi before dawn, catch sunrise near the lake and return after an easy morning outdoors.',
      'public',
      'approval_required',
      'fixed',
      date_trunc('day', now()) + interval '30 days' + interval '4 hours',
      date_trunc('day', now()) + interval '30 days' + interval '13 hours',
      'Africa/Nairobi',
      'Nairobi CBD',
      8,
      'published',
      'approved',
      now() - interval '2 hours',
      now()
    )
  on conflict (id) do update set
    title = excluded.title,
    summary = excluded.summary,
    cover_image_url = excluded.cover_image_url,
    description = excluded.description,
    visibility = excluded.visibility,
    join_policy = excluded.join_policy,
    schedule_type = excluded.schedule_type,
    starts_at = excluded.starts_at,
    ends_at = excluded.ends_at,
    meeting_point = excluded.meeting_point,
    max_participants = excluded.max_participants,
    status = 'published',
    moderation_status = 'approved',
    updated_at = now();

  insert into public.quest_items (
    quest_id,
    item_type,
    county_id,
    title,
    description,
    position
  ) values
    (v_public_food_id, 'county', 47, 'Nairobi', 'Meet and complete the food crawl.', 0),
    (v_friends_aberdare_id, 'county', 18, 'Nyandarua', 'Camp and explore the Aberdare area.', 0),
    (v_public_naivasha_id, 'county', 32, 'Nakuru', 'Sunrise and lakeside walk in Naivasha.', 0)
  on conflict do nothing;

  insert into public.quest_members (
    quest_id,
    user_id,
    role,
    membership_status,
    joined_at,
    responded_at
  ) values
    (v_public_food_id, v_user_id, 'owner', 'joined', now(), now()),
    (v_friends_aberdare_id, v_user_id, 'owner', 'joined', now(), now()),
    (v_public_naivasha_id, v_user_id, 'owner', 'joined', now(), now()),
    (v_editorial_coast_id, v_user_id, 'member', 'joined', now(), now()),
    (v_editorial_rift_id, v_user_id, 'member', 'joined', now(), now()),
    (v_editorial_heritage_id, v_user_id, 'member', 'joined', now(), now())
  on conflict (quest_id, user_id) do update set
    role = excluded.role,
    membership_status = 'joined',
    joined_at = coalesce(public.quest_members.joined_at, excluded.joined_at),
    responded_at = excluded.responded_at;

  return format(
    'Seeded 3 editorial + 3 community Side Quests for %s (%s).',
    coalesce(v_user.email, p_identifier),
    v_user_id
  );
end;
$$;

revoke execute on function public.dev_seed_social_quests(text, boolean) from public;
revoke execute on function public.dev_seed_social_quests(text, boolean) from authenticated;
grant execute on function public.dev_seed_social_quests(text, boolean) to service_role;

-- Ready-to-run seed query for the requested development account:
-- select public.dev_seed_social_quests('kokodavid78@gmail.com');

-- Service-role verification query:
-- select q.title, q.publisher_kind, q.visibility, q.join_policy, q.starts_at
-- from public.quests q
-- where q.publisher_kind = 'editorial'
--    or q.created_by = (
--      select id from auth.users where lower(email) = 'kokodavid78@gmail.com'
--    )
-- order by q.publisher_kind, q.starts_at nulls last;
