-- content_origin (20260918120000_add_place_content_origin.sql) tags where a
-- row came from, but that's permanent provenance -- editing a seed-migration
-- place through update_place_dashboard_profile never changes it, so there
-- was no way to say "yes, someone has reviewed and confirmed this one" and
-- have it drop off the unreviewed count. reviewed_at is a separate,
-- explicit review-status flag an editor sets on purpose, independent of any
-- profile edit.

alter table public.places
  add column if not exists reviewed_at timestamptz;

comment on column public.places.reviewed_at is
  'When an editor explicitly marked this place as reviewed via set_place_reviewed_dashboard. Null means unreviewed. Independent of content_origin and not touched by update_place_dashboard_profile.';

create or replace function public.set_place_reviewed_dashboard(
  p_place_id uuid,
  p_reviewed boolean
)
returns public.places
language plpgsql
security definer
set search_path = public
as $$
declare
  v_role public.admin_role;
  v_place public.places;
begin
  v_role := public.current_admin_role();

  if v_role not in ('owner', 'admin', 'editor') then
    raise exception 'Marking a place reviewed requires owner, admin, or editor access'
      using errcode = '42501';
  end if;

  if p_place_id is null then
    raise exception 'Place id is required'
      using errcode = '22023';
  end if;

  update public.places
  set reviewed_at = case when p_reviewed then now() else null end
  where id = p_place_id
  returning * into v_place;

  if not found then
    raise exception 'Place % was not found', p_place_id
      using errcode = 'P0002';
  end if;

  return v_place;
end;
$$;

revoke all on function public.set_place_reviewed_dashboard(uuid, boolean) from public;
grant execute on function public.set_place_reviewed_dashboard(uuid, boolean) to authenticated;
