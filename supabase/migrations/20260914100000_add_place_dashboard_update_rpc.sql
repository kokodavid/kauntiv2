-- Dashboard place editing.
--
-- Coordinates/location and image metadata stay out of this RPC's write
-- path -- geometry needs its own review (see docs/dashboard-development-plan.md
-- "Open Decisions"), and images get their own narrowly scoped RPCs next.
-- external_id is the dev-seed idempotency key (see
-- docs/dev-county-gap-places-report.md) and is never dashboard-editable.

create or replace function public.update_place_dashboard_profile(
  p_place_id uuid,
  p_name text,
  p_type text,
  p_summary text,
  p_description text,
  p_source text,
  p_source_url text,
  p_licence text,
  p_last_verified_at date
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
    raise exception 'Place editing requires owner, admin, or editor access'
      using errcode = '42501';
  end if;

  if p_place_id is null then
    raise exception 'Place id is required'
      using errcode = '22023';
  end if;

  if nullif(btrim(p_name), '') is null then
    raise exception 'Name cannot be empty'
      using errcode = '22023';
  end if;

  if nullif(btrim(p_type), '') is null then
    raise exception 'Type cannot be empty'
      using errcode = '22023';
  end if;

  if nullif(btrim(p_source), '') is null then
    raise exception 'Source cannot be empty'
      using errcode = '22023';
  end if;

  if p_last_verified_at is not null and p_last_verified_at > current_date then
    raise exception 'Last verified date cannot be in the future'
      using errcode = '22023';
  end if;

  update public.places
  set
    name = btrim(p_name),
    type = btrim(p_type),
    summary = nullif(btrim(p_summary), ''),
    description = nullif(btrim(p_description), ''),
    source = btrim(p_source),
    source_url = nullif(btrim(p_source_url), ''),
    licence = nullif(btrim(p_licence), ''),
    last_verified_at = p_last_verified_at
  where id = p_place_id
  returning * into v_place;

  if not found then
    raise exception 'Place % was not found', p_place_id
      using errcode = 'P0002';
  end if;

  return v_place;
end;
$$;

revoke execute on function public.update_place_dashboard_profile(
  uuid,
  text,
  text,
  text,
  text,
  text,
  text,
  text,
  date
) from public;

grant execute on function public.update_place_dashboard_profile(
  uuid,
  text,
  text,
  text,
  text,
  text,
  text,
  text,
  date
) to authenticated;
