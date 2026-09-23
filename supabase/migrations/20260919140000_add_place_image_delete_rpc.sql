-- add_place_image_dashboard_entry's own header comment (and
-- docs/dashboard-development-plan.md's "Place Image Management" entry)
-- deliberately held off on exposing image deletion until an audit/history
-- story existed, per the project's general "avoid destructive actions
-- until an audit/history story exists" rule. Revisited on explicit
-- request: this is a real hard delete, with no undo and no history row.
--
-- Returns the deleted row so the dashboard can clean up the corresponding
-- object in the place-images Storage bucket for dashboard-uploaded images
-- (image_url/thumbnail_url pointing outside that bucket, e.g. Wikimedia
-- Commons, are simply left alone -- nothing to remove).

create or replace function public.delete_place_image_dashboard_entry(
  p_image_id uuid
)
returns public.place_images
language plpgsql
security definer
set search_path = public
as $$
declare
  v_role public.admin_role;
  v_image public.place_images;
begin
  v_role := public.current_admin_role();
  if v_role not in ('owner', 'admin', 'editor') then
    raise exception 'Place image management requires owner, admin, or editor access'
      using errcode = '42501';
  end if;

  if p_image_id is null then
    raise exception 'p_image_id is required' using errcode = '22004';
  end if;

  delete from public.place_images
  where id = p_image_id
  returning * into v_image;

  if not found then
    raise exception 'Image % was not found', p_image_id
      using errcode = 'P0002';
  end if;

  return v_image;
end;
$$;

revoke all on function public.delete_place_image_dashboard_entry(uuid) from public;
grant execute on function public.delete_place_image_dashboard_entry(uuid) to authenticated;
