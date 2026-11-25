-- Dashboard switch for places shown on the public landing site.
--
-- Sets places.featured_on_site (read by get_public_places()). Same access rule
-- as set_place_reviewed_dashboard: owner, admin or editor. A place can only be
-- featured while it is reviewed and not archived; switching off is always allowed.

alter table public.places
  add column if not exists featured_on_site boolean not null default false;

create or replace function public.set_place_featured_dashboard(
  p_place_id uuid,
  p_featured boolean
)
returns public.places
language plpgsql
security definer
set search_path = public
as $$
declare
  v_place public.places;
begin
  if public.current_admin_role() not in ('owner', 'admin', 'editor') then
    raise exception 'Featuring a place requires owner, admin, or editor access'
      using errcode = '42501';
  end if;
  if p_place_id is null or p_featured is null then
    raise exception 'Place id and featured flag are required' using errcode = '22023';
  end if;

  if p_featured then
    perform 1 from public.places
    where id = p_place_id and status = 'reviewed' and archived_at is null;
    if not found then
      raise exception 'Only reviewed, non-archived places can be shown on the site'
        using errcode = '22023';
    end if;
  end if;

  update public.places
  set featured_on_site = p_featured
  where id = p_place_id
  returning * into v_place;

  if not found then
    raise exception 'Place % was not found', p_place_id using errcode = 'P0002';
  end if;
  return v_place;
end;
$$;

revoke all on function public.set_place_featured_dashboard(uuid, boolean) from public;
grant execute on function public.set_place_featured_dashboard(uuid, boolean) to authenticated;
