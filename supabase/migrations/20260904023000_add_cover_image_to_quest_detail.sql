-- Expose the existing quest cover image through the detail RPC. This is a
-- separate migration so environments that already applied the social quest
-- schema receive the updated JSON contract.
update public.quests
set cover_image_url = case title
  when 'Coast Before Christmas' then
    'https://thumb.wikimedia.org/wikipedia/commons/thumb/f/fa/Fun_at_Shelly_Beach_Mombasa.jpg/1280px-Fun_at_Shelly_Beach_Mombasa.jpg'
  when 'Great Rift Valley Explorer' then
    'https://thumb.wikimedia.org/wikipedia/commons/thumb/c/cc/Zebra_Lake_Nakuru-close_view.jpg/1280px-Zebra_Lake_Nakuru-close_view.jpg'
  when 'Kenya Heritage Trail' then
    'https://thumb.wikimedia.org/wikipedia/commons/thumb/3/34/Traditional_dhow_sailboat_in_Lamu%2C_Kenya.jpg/1280px-Traditional_dhow_sailboat_in_Lamu%2C_Kenya.jpg'
  when 'Nairobi Saturday Food Crawl' then
    'https://thumb.wikimedia.org/wikipedia/commons/thumb/3/33/Gyps_rueppellii_-Nairobi_National_Park%2C_Kenya-8-4c.jpg/1280px-Gyps_rueppellii_-Nairobi_National_Park%2C_Kenya-8-4c.jpg'
  when 'Aberdare Friends Weekend' then
    'https://thumb.wikimedia.org/wikipedia/commons/thumb/5/5f/Lake_Olbolosat.jpg/1280px-Lake_Olbolosat.jpg'
  when 'Lake Naivasha Sunrise Drive' then
    'https://thumb.wikimedia.org/wikipedia/commons/thumb/c/cc/Zebra_Lake_Nakuru-close_view.jpg/1280px-Zebra_Lake_Nakuru-close_view.jpg'
end
where title in (
  'Coast Before Christmas',
  'Great Rift Valley Explorer',
  'Kenya Heritage Trail',
  'Nairobi Saturday Food Crawl',
  'Aberdare Friends Weekend',
  'Lake Naivasha Sunrise Drive'
);

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
