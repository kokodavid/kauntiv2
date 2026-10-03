-- A user-chosen photo representing a Trip in its history card and share
-- image (Claude-Design "Trip Share Card" reference). NULL means no
-- explicit choice has been made yet; the client falls back to the
-- Trip's earliest photo, and to a no-photo brand treatment when it has
-- none. `on delete set null` so deleting the chosen photo just reverts
-- the Trip to that default rather than leaving a dangling reference.
alter table public.journeys
  add column cover_media_id uuid references public.journey_media (id) on delete set null;

-- Lets a user set (or clear, with a null p_media_id) their own Trip's
-- cover photo. journeys has no client update policy (see 20260925130000):
-- this security-definer RPC is the only write path, mirroring
-- rename_journey. Unlike a plain title, this also has to check the photo
-- actually belongs to this Trip - journey_media and journeys are
-- otherwise unrelated here, so without this check any signed-in user
-- could point a Trip at someone else's photo.
create function public.set_trip_cover_photo(
  p_user_id uuid,
  p_journey_id uuid,
  p_media_id uuid
)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if auth.uid() is null or auth.uid() <> p_user_id then
    raise exception 'Journey owner does not match the signed-in account'
      using errcode = '42501';
  end if;

  if p_media_id is not null and not exists (
    select 1 from public.journey_media
    where id = p_media_id
      and journey_id = p_journey_id
      and user_id = p_user_id
  ) then
    raise exception 'Photo does not belong to this Trip' using errcode = '22023';
  end if;

  update public.journeys
  set cover_media_id = p_media_id
  where id = p_journey_id and user_id = p_user_id;

  if not found then
    raise exception 'Journey not found for this account' using errcode = 'P0002';
  end if;
end;
$$;

revoke execute on function public.set_trip_cover_photo(uuid, uuid, uuid) from public;
grant execute on function public.set_trip_cover_photo(uuid, uuid, uuid) to authenticated;
