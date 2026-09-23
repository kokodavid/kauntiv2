-- Unified editorial + community Side Quests.
--
-- Community quests can be public or restricted to accepted friends. Joining
-- is handled by RPCs so visibility, approval and capacity are checked in one
-- transaction rather than trusted to the Flutter client.

create table if not exists public.quest_public_profiles (
  user_id uuid primary key references auth.users (id) on delete cascade,
  display_name text not null check (char_length(display_name) between 1 and 80),
  handle text not null unique check (handle ~ '^[a-z0-9][a-z0-9_-]{2,29}$'),
  avatar_url text,
  updated_at timestamptz not null default now()
);

alter table public.quest_public_profiles enable row level security;

create policy "Signed-in users can read quest public profiles"
  on public.quest_public_profiles for select to authenticated using (true);

create policy "Users can create their own quest public profile"
  on public.quest_public_profiles for insert to authenticated
  with check (user_id = auth.uid());

create policy "Users can update their own quest public profile"
  on public.quest_public_profiles for update to authenticated
  using (user_id = auth.uid()) with check (user_id = auth.uid());

-- Give existing and future accounts a safe, separately-readable identity.
-- The UUID suffix keeps handles unique until users choose their own.
insert into public.quest_public_profiles (user_id, display_name, handle, avatar_url)
select
  u.id,
  left(coalesce(u.raw_user_meta_data ->> 'full_name',
                u.raw_user_meta_data ->> 'name',
                split_part(coalesce(u.email, 'Traveler'), '@', 1),
                'Traveler'), 80),
  'user-' || left(replace(u.id::text, '-', ''), 8),
  coalesce(u.raw_user_meta_data ->> 'avatar_url', u.raw_user_meta_data ->> 'picture')
from auth.users u
on conflict (user_id) do nothing;

create or replace function public.create_quest_public_profile_for_new_user()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  insert into public.quest_public_profiles (user_id, display_name, handle, avatar_url)
  values (
    new.id,
    left(coalesce(new.raw_user_meta_data ->> 'full_name',
                  new.raw_user_meta_data ->> 'name',
                  split_part(coalesce(new.email, 'Traveler'), '@', 1),
                  'Traveler'), 80),
    'user-' || left(replace(new.id::text, '-', ''), 8),
    coalesce(new.raw_user_meta_data ->> 'avatar_url', new.raw_user_meta_data ->> 'picture')
  ) on conflict (user_id) do nothing;
  return new;
end;
$$;

drop trigger if exists create_quest_public_profile_after_signup on auth.users;
create trigger create_quest_public_profile_after_signup
  after insert on auth.users
  for each row execute function public.create_quest_public_profile_for_new_user();

create table if not exists public.friendships (
  id uuid primary key default gen_random_uuid(),
  requested_by uuid not null references auth.users (id) on delete cascade,
  requested_to uuid not null references auth.users (id) on delete cascade,
  status text not null default 'pending'
    check (status in ('pending', 'accepted', 'declined', 'blocked')),
  created_at timestamptz not null default now(),
  responded_at timestamptz,
  check (requested_by <> requested_to)
);

create unique index if not exists friendships_pair_uidx
  on public.friendships (
    least(requested_by, requested_to),
    greatest(requested_by, requested_to)
  );

create index if not exists friendships_requested_by_idx
  on public.friendships (requested_by, status);
create index if not exists friendships_requested_to_idx
  on public.friendships (requested_to, status);

alter table public.friendships enable row level security;

create policy "Friendship participants can read the relationship"
  on public.friendships for select to authenticated
  using (auth.uid() in (requested_by, requested_to));

create policy "Users can send friendship requests"
  on public.friendships for insert to authenticated
  with check (auth.uid() = requested_by and status = 'pending');

create table if not exists public.quests (
  id uuid primary key default gen_random_uuid(),
  created_by uuid references public.quest_public_profiles (user_id) on delete set null,
  publisher_kind text not null check (publisher_kind in ('editorial', 'community')),
  publisher_name text,
  quest_kind text not null check (quest_kind in ('trip', 'challenge')),
  title text not null check (char_length(title) between 3 and 100),
  summary text not null check (char_length(summary) between 3 and 240),
  description text not null default '',
  cover_image_url text,
  visibility text not null default 'public'
    check (visibility in ('public', 'friends_only')),
  join_policy text not null default 'open'
    check (join_policy in ('open', 'approval_required', 'closed')),
  schedule_type text not null default 'tbd'
    check (schedule_type in ('fixed', 'flexible', 'tbd')),
  starts_at timestamptz,
  ends_at timestamptz,
  timezone text not null default 'Africa/Nairobi',
  meeting_point text,
  estimated_cost text,
  difficulty text,
  max_participants integer check (max_participants is null or max_participants >= 2),
  required_count integer check (required_count is null or required_count > 0),
  status text not null default 'draft'
    check (status in ('draft', 'published', 'cancelled', 'completed', 'archived')),
  moderation_status text not null default 'approved'
    check (moderation_status in ('pending', 'approved', 'rejected')),
  published_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (publisher_kind = 'editorial' or created_by is not null),
  check (ends_at is null or starts_at is null or ends_at >= starts_at),
  check (schedule_type <> 'fixed' or starts_at is not null)
);

create index if not exists quests_feed_idx
  on public.quests (status, moderation_status, starts_at, published_at desc);
create index if not exists quests_created_by_idx on public.quests (created_by);

create table if not exists public.quest_items (
  id uuid primary key default gen_random_uuid(),
  quest_id uuid not null references public.quests (id) on delete cascade,
  item_type text not null check (item_type in ('county', 'place', 'activity', 'custom')),
  county_id smallint references public.counties (id),
  place_id uuid references public.places (id),
  title text not null check (char_length(title) between 1 and 120),
  description text not null default '',
  position integer not null default 0 check (position >= 0),
  scheduled_at timestamptz,
  is_required boolean not null default true
);

create index if not exists quest_items_quest_idx
  on public.quest_items (quest_id, position);

create table if not exists public.quest_members (
  quest_id uuid not null references public.quests (id) on delete cascade,
  user_id uuid not null references auth.users (id) on delete cascade,
  role text not null default 'member' check (role in ('owner', 'cohost', 'member')),
  membership_status text not null
    check (membership_status in ('invited', 'requested', 'joined', 'declined', 'left', 'removed')),
  joined_at timestamptz,
  responded_at timestamptz,
  created_at timestamptz not null default now(),
  primary key (quest_id, user_id)
);

create index if not exists quest_members_user_idx
  on public.quest_members (user_id, membership_status);

alter table public.quests enable row level security;
alter table public.quest_items enable row level security;
alter table public.quest_members enable row level security;

create or replace function public.are_friends(p_left uuid, p_right uuid)
returns boolean
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select exists (
    select 1 from public.friendships f
    where f.status = 'accepted'
      and ((f.requested_by = p_left and f.requested_to = p_right)
        or (f.requested_by = p_right and f.requested_to = p_left))
  );
$$;

create or replace function public.can_view_quest(p_quest_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select exists (
    select 1
    from public.quests q
    where q.id = p_quest_id
      and (
        q.created_by = auth.uid()
        or exists (
          select 1 from public.quest_members m
          where m.quest_id = q.id and m.user_id = auth.uid()
            and m.membership_status in ('invited', 'requested', 'joined')
        )
        or (
          q.status = 'published'
          and q.moderation_status = 'approved'
          and (
            q.publisher_kind = 'editorial'
            or q.visibility = 'public'
            or public.are_friends(q.created_by, auth.uid())
          )
        )
      )
  );
$$;

revoke execute on function public.are_friends(uuid, uuid) from public;
revoke execute on function public.can_view_quest(uuid) from public;
grant execute on function public.can_view_quest(uuid) to authenticated;

create policy "Eligible users can read quests"
  on public.quests for select to authenticated
  using (public.can_view_quest(id));

create policy "Creators can update their quests"
  on public.quests for update to authenticated
  using (created_by = auth.uid() and publisher_kind = 'community')
  with check (created_by = auth.uid() and publisher_kind = 'community');

create policy "Eligible users can read quest items"
  on public.quest_items for select to authenticated
  using (public.can_view_quest(quest_id));

create policy "Creators can manage quest items"
  on public.quest_items for all to authenticated
  using (exists (
    select 1 from public.quests q where q.id = quest_id and q.created_by = auth.uid()
  ))
  with check (exists (
    select 1 from public.quests q where q.id = quest_id and q.created_by = auth.uid()
  ));

create or replace function public.is_quest_participant(
  p_quest_id uuid
)
returns boolean
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select exists (
    select 1 from public.quest_members m
    where m.quest_id = p_quest_id and m.user_id = auth.uid()
      and m.membership_status = 'joined'
  );
$$;

revoke execute on function public.is_quest_participant(uuid) from public;
grant execute on function public.is_quest_participant(uuid) to authenticated;

create or replace function public.quest_joined_count(p_quest_id uuid)
returns bigint
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select count(*) from public.quest_members m
  where m.quest_id = p_quest_id and m.membership_status = 'joined';
$$;

revoke execute on function public.quest_joined_count(uuid) from public;
grant execute on function public.quest_joined_count(uuid) to authenticated;

create policy "Quest participants can read memberships"
  on public.quest_members for select to authenticated
  using (
    user_id = auth.uid()
    or exists (
      select 1 from public.quests q where q.id = quest_id and q.created_by = auth.uid()
    )
    or public.is_quest_participant(quest_id)
  );

create or replace function public.respond_to_friend_request(
  p_friendship_id uuid,
  p_accept boolean
)
returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  update public.friendships
  set status = case when p_accept then 'accepted' else 'declined' end,
      responded_at = now()
  where id = p_friendship_id and requested_to = auth.uid() and status = 'pending';
  if not found then raise exception 'Friend request not found'; end if;
end;
$$;

revoke execute on function public.respond_to_friend_request(uuid, boolean) from public;
grant execute on function public.respond_to_friend_request(uuid, boolean) to authenticated;

create or replace function public.send_friend_request(p_user_id uuid)
returns uuid
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_id uuid;
begin
  if auth.uid() is null or p_user_id = auth.uid() then
    raise exception 'Choose another user';
  end if;
  if not exists (select 1 from public.quest_public_profiles where user_id = p_user_id) then
    raise exception 'User not found';
  end if;
  insert into public.friendships (requested_by, requested_to, status)
  values (auth.uid(), p_user_id, 'pending')
  returning id into v_id;
  return v_id;
exception
  when unique_violation then
    raise exception 'A friendship or request already exists';
end;
$$;

create or replace function public.friend_connections()
returns table (
  friendship_id uuid,
  user_id uuid,
  display_name text,
  handle text,
  avatar_url text,
  friendship_status text,
  direction text
)
language sql
stable
security invoker
as $$
  select
    f.id,
    case when f.requested_by = auth.uid() then f.requested_to else f.requested_by end,
    p.display_name,
    p.handle,
    p.avatar_url,
    f.status,
    case when f.requested_to = auth.uid() then 'incoming' else 'outgoing' end
  from public.friendships f
  join public.quest_public_profiles p
    on p.user_id = case when f.requested_by = auth.uid()
      then f.requested_to else f.requested_by end
  order by case f.status when 'pending' then 0 else 1 end, p.display_name;
$$;

create or replace function public.find_people(p_query text, p_limit integer default 20)
returns table (
  user_id uuid,
  display_name text,
  handle text,
  avatar_url text,
  friendship_status text
)
language sql
stable
security invoker
as $$
  select
    p.user_id,
    p.display_name,
    p.handle,
    p.avatar_url,
    (
      select f.status from public.friendships f
      where (f.requested_by = auth.uid() and f.requested_to = p.user_id)
         or (f.requested_to = auth.uid() and f.requested_by = p.user_id)
    )
  from public.quest_public_profiles p
  where p.user_id <> auth.uid()
    and (p.display_name ilike '%' || trim(p_query) || '%'
      or p.handle ilike '%' || trim(p_query) || '%')
  order by p.display_name
  limit least(greatest(p_limit, 1), 50);
$$;

revoke execute on function public.send_friend_request(uuid) from public;
grant execute on function public.send_friend_request(uuid) to authenticated;
revoke execute on function public.friend_connections() from public;
grant execute on function public.friend_connections() to authenticated;
revoke execute on function public.find_people(text, integer) from public;
grant execute on function public.find_people(text, integer) to authenticated;

create or replace function public.ensure_quest_public_profile()
returns public.quest_public_profiles
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_profile public.quest_public_profiles;
  v_base text;
begin
  if auth.uid() is null then raise exception 'Authentication required'; end if;

  select * into v_profile from public.quest_public_profiles where user_id = auth.uid();
  if found then return v_profile; end if;

  v_base := lower(regexp_replace(
    coalesce(auth.jwt() -> 'user_metadata' ->> 'preferred_username',
             split_part(coalesce(auth.jwt() ->> 'email', 'traveler'), '@', 1),
             'traveler'),
    '[^a-z0-9_-]+', '-', 'g'
  ));
  v_base := trim(both '-_' from v_base);
  if char_length(v_base) < 3 then v_base := 'traveler'; end if;
  if v_base !~ '^[a-z0-9]' then v_base := 'u-' || v_base; end if;
  v_base := left(v_base, 21) || '-' || left(replace(auth.uid()::text, '-', ''), 8);

  insert into public.quest_public_profiles (user_id, display_name, handle, avatar_url)
  values (
    auth.uid(),
    left(coalesce(auth.jwt() -> 'user_metadata' ->> 'full_name',
                  auth.jwt() -> 'user_metadata' ->> 'name',
                  split_part(coalesce(auth.jwt() ->> 'email', 'Traveler'), '@', 1),
                  'Traveler'), 80),
    left(v_base, 30),
    coalesce(auth.jwt() -> 'user_metadata' ->> 'avatar_url',
             auth.jwt() -> 'user_metadata' ->> 'picture')
  )
  returning * into v_profile;
  return v_profile;
end;
$$;

revoke execute on function public.ensure_quest_public_profile() from public;
grant execute on function public.ensure_quest_public_profile() to authenticated;

create or replace function public.create_quest(
  p_title text,
  p_summary text,
  p_quest_kind text,
  p_visibility text,
  p_join_policy text default 'open',
  p_schedule_type text default 'tbd',
  p_starts_at timestamptz default null,
  p_ends_at timestamptz default null,
  p_timezone text default 'Africa/Nairobi',
  p_description text default '',
  p_meeting_point text default null,
  p_max_participants integer default null,
  p_items jsonb default '[]'::jsonb
)
returns uuid
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_quest_id uuid;
  v_item jsonb;
  v_position integer := 0;
begin
  if auth.uid() is null then raise exception 'Authentication required'; end if;
  if jsonb_typeof(p_items) <> 'array' or jsonb_array_length(p_items) = 0 then
    raise exception 'A quest needs at least one destination or activity';
  end if;

  perform public.ensure_quest_public_profile();

  insert into public.quests (
    created_by, publisher_kind, quest_kind, title, summary, description,
    visibility, join_policy, schedule_type, starts_at, ends_at, timezone,
    meeting_point, max_participants, status, moderation_status, published_at
  ) values (
    auth.uid(), 'community', p_quest_kind, trim(p_title), trim(p_summary), trim(p_description),
    p_visibility, p_join_policy, p_schedule_type, p_starts_at, p_ends_at,
    coalesce(nullif(trim(p_timezone), ''), 'Africa/Nairobi'), nullif(trim(p_meeting_point), ''),
    p_max_participants, 'published', 'approved', now()
  ) returning id into v_quest_id;

  insert into public.quest_members (quest_id, user_id, role, membership_status, joined_at)
  values (v_quest_id, auth.uid(), 'owner', 'joined', now());

  for v_item in select value from jsonb_array_elements(p_items) loop
    insert into public.quest_items (
      quest_id, item_type, county_id, place_id, title, description, position,
      scheduled_at, is_required
    ) values (
      v_quest_id,
      coalesce(v_item ->> 'item_type', 'custom'),
      case when nullif(v_item ->> 'county_id', '') is null then null
           else (v_item ->> 'county_id')::smallint end,
      case when nullif(v_item ->> 'place_id', '') is null then null
           else (v_item ->> 'place_id')::uuid end,
      trim(v_item ->> 'title'),
      coalesce(trim(v_item ->> 'description'), ''),
      coalesce((v_item ->> 'position')::integer, v_position),
      case when nullif(v_item ->> 'scheduled_at', '') is null then null
           else (v_item ->> 'scheduled_at')::timestamptz end,
      coalesce((v_item ->> 'is_required')::boolean, true)
    );
    v_position := v_position + 1;
  end loop;

  return v_quest_id;
end;
$$;

revoke execute on function public.create_quest(text, text, text, text, text, text, timestamptz, timestamptz, text, text, text, integer, jsonb) from public;
grant execute on function public.create_quest(text, text, text, text, text, text, timestamptz, timestamptz, text, text, text, integer, jsonb) to authenticated;

create or replace function public.join_quest(p_quest_id uuid)
returns text
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_quest public.quests;
  v_joined_count integer;
  v_status text;
begin
  if auth.uid() is null then raise exception 'Authentication required'; end if;
  perform public.ensure_quest_public_profile();
  select * into v_quest from public.quests where id = p_quest_id for update;
  if not found or not public.can_view_quest(p_quest_id) then raise exception 'Quest not found'; end if;
  if v_quest.created_by = auth.uid() then return 'joined'; end if;
  if v_quest.status <> 'published' or v_quest.join_policy = 'closed' then
    raise exception 'This quest is not accepting participants';
  end if;
  if v_quest.visibility = 'friends_only'
    and not public.are_friends(v_quest.created_by, auth.uid()) then
    raise exception 'Only the creator''s friends can join this quest';
  end if;

  select count(*) into v_joined_count from public.quest_members
  where quest_id = p_quest_id and membership_status = 'joined';
  if v_quest.max_participants is not null and v_joined_count >= v_quest.max_participants then
    raise exception 'This quest is full';
  end if;

  v_status := case when v_quest.join_policy = 'approval_required'
    then 'requested' else 'joined' end;
  insert into public.quest_members (
    quest_id, user_id, role, membership_status, joined_at, responded_at
  ) values (
    p_quest_id, auth.uid(), 'member', v_status,
    case when v_status = 'joined' then now() else null end,
    case when v_status = 'joined' then now() else null end
  )
  on conflict (quest_id, user_id) do update set
    membership_status = excluded.membership_status,
    joined_at = excluded.joined_at,
    responded_at = excluded.responded_at;
  return v_status;
end;
$$;

create or replace function public.respond_to_quest_request(
  p_quest_id uuid,
  p_user_id uuid,
  p_approve boolean
)
returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_max integer;
  v_count integer;
begin
  select max_participants into v_max from public.quests
  where id = p_quest_id and created_by = auth.uid() for update;
  if not found then raise exception 'Only the quest owner can respond'; end if;
  if p_approve and v_max is not null then
    select count(*) into v_count from public.quest_members
    where quest_id = p_quest_id and membership_status = 'joined';
    if v_count >= v_max then raise exception 'This quest is full'; end if;
  end if;
  update public.quest_members set
    membership_status = case when p_approve then 'joined' else 'declined' end,
    joined_at = case when p_approve then now() else null end,
    responded_at = now()
  where quest_id = p_quest_id and user_id = p_user_id
    and membership_status = 'requested';
  if not found then raise exception 'Join request not found'; end if;
end;
$$;

create or replace function public.leave_quest(p_quest_id uuid)
returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  update public.quest_members set membership_status = 'left', responded_at = now()
  where quest_id = p_quest_id and user_id = auth.uid() and role <> 'owner';
end;
$$;

revoke execute on function public.join_quest(uuid) from public;
grant execute on function public.join_quest(uuid) to authenticated;
revoke execute on function public.respond_to_quest_request(uuid, uuid, boolean) from public;
grant execute on function public.respond_to_quest_request(uuid, uuid, boolean) to authenticated;
revoke execute on function public.leave_quest(uuid) from public;
grant execute on function public.leave_quest(uuid) to authenticated;

create or replace function public.side_quests_feed(p_limit integer default 20)
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
  is_owner boolean
)
language sql
stable
security invoker
as $$
  select
    q.id,
    q.publisher_kind,
    coalesce(p.display_name, q.publisher_name, 'Kaunti47'),
    p.handle,
    p.avatar_url,
    q.quest_kind,
    q.title,
    q.summary,
    q.visibility,
    q.join_policy,
    q.schedule_type,
    q.starts_at,
    q.ends_at,
    public.quest_joined_count(q.id),
    q.max_participants,
    (select m.membership_status from public.quest_members m
      where m.quest_id = q.id and m.user_id = auth.uid()),
    q.created_by = auth.uid()
  from public.quests q
  left join public.quest_public_profiles p on p.user_id = q.created_by
  where q.status = 'published'
    and q.moderation_status = 'approved'
    and (q.ends_at is null or q.ends_at >= now())
  order by
    case when exists (
      select 1 from public.quest_members mine
      where mine.quest_id = q.id and mine.user_id = auth.uid()
        and mine.membership_status in ('invited', 'requested', 'joined')
    ) then 0 else 1 end,
    q.starts_at asc nulls last,
    q.published_at desc
  limit least(greatest(p_limit, 1), 50);
$$;

revoke execute on function public.side_quests_feed(integer) from public;
grant execute on function public.side_quests_feed(integer) to authenticated;

create or replace function public.quest_detail(p_quest_id uuid)
returns jsonb
language sql
stable
security invoker
as $$
  select jsonb_build_object(
    'quest_id', q.id,
    'publisher_kind', q.publisher_kind,
    'publisher_name', coalesce(p.display_name, q.publisher_name, 'Kaunti47'),
    'publisher_handle', p.handle,
    'publisher_avatar_url', p.avatar_url,
    'quest_kind', q.quest_kind,
    'title', q.title,
    'summary', q.summary,
    'cover_image_url', q.cover_image_url,
    'description', q.description,
    'visibility', q.visibility,
    'join_policy', q.join_policy,
    'schedule_type', q.schedule_type,
    'starts_at', q.starts_at,
    'ends_at', q.ends_at,
    'timezone', q.timezone,
    'meeting_point', q.meeting_point,
    'max_participants', q.max_participants,
    'joined_count', public.quest_joined_count(q.id),
    'viewer_membership_status', (select m.membership_status from public.quest_members m
      where m.quest_id = q.id and m.user_id = auth.uid()),
    'is_owner', q.created_by = auth.uid(),
    'items', coalesce((
      select jsonb_agg(jsonb_build_object(
        'id', i.id, 'item_type', i.item_type, 'county_id', i.county_id,
        'place_id', i.place_id, 'title', i.title, 'description', i.description,
        'position', i.position, 'scheduled_at', i.scheduled_at,
        'is_required', i.is_required
      ) order by i.position)
      from public.quest_items i where i.quest_id = q.id
    ), '[]'::jsonb),
    'members', coalesce((
      select jsonb_agg(jsonb_build_object(
        'user_id', m.user_id, 'display_name', mp.display_name,
        'handle', mp.handle, 'avatar_url', mp.avatar_url,
        'role', m.role, 'membership_status', m.membership_status
      ) order by m.created_at)
      from public.quest_members m
      left join public.quest_public_profiles mp on mp.user_id = m.user_id
      where m.quest_id = q.id
        and (m.membership_status in ('joined', 'requested') or m.user_id = auth.uid())
    ), '[]'::jsonb)
  )
  from public.quests q
  left join public.quest_public_profiles p on p.user_id = q.created_by
  where q.id = p_quest_id;
$$;

revoke execute on function public.quest_detail(uuid) from public;
grant execute on function public.quest_detail(uuid) to authenticated;

-- Move existing authored quests into the unified feed. Keeping the old tables
-- temporarily makes the migration reversible and preserves existing progress.
insert into public.quests (
  id, publisher_kind, publisher_name, quest_kind, title, summary, visibility,
  join_policy, schedule_type, starts_at, ends_at, required_count, status,
  moderation_status, published_at
)
select
  q.id, 'editorial', 'Kaunti47', 'challenge', q.title,
  'An official Kaunti47 challenge.', 'public', 'open', 'fixed',
  q.starts_at, q.ends_at, q.required_count, 'published', 'approved', q.starts_at
from public.editorial_quests q
on conflict (id) do nothing;
