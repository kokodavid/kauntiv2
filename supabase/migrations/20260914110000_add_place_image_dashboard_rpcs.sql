-- Narrowly scoped RPCs for dashboard-driven place_images management.
-- Mirrors update_place_dashboard_profile's role gate and validation style.
-- Deletion/deactivation of images is intentionally NOT exposed yet -- see
-- docs/dashboard-development-plan.md "Place Image Management" roadmap item.

create or replace function public.add_place_image_dashboard_entry(
  p_place_id uuid,
  p_image_url text,
  p_thumbnail_url text,
  p_source text,
  p_source_url text,
  p_licence text,
  p_licence_url text,
  p_attribution text
)
returns public.place_images
language plpgsql
security definer
set search_path = public
as $$
declare
  v_role public.admin_role;
  v_image public.place_images;
  v_sort_order integer;
begin
  v_role := public.current_admin_role();
  if v_role not in ('owner', 'admin', 'editor') then
    raise exception 'Place image management requires owner, admin, or editor access'
      using errcode = '42501';
  end if;

  if p_place_id is null then
    raise exception 'p_place_id is required' using errcode = '22004';
  end if;

  if not exists (select 1 from public.places where id = p_place_id) then
    raise exception 'Place % was not found', p_place_id using errcode = 'P0002';
  end if;

  if btrim(coalesce(p_image_url, '')) = '' then
    raise exception 'p_image_url is required' using errcode = '22004';
  end if;

  if btrim(coalesce(p_thumbnail_url, '')) = '' then
    raise exception 'p_thumbnail_url is required' using errcode = '22004';
  end if;

  if btrim(coalesce(p_source, '')) = '' then
    raise exception 'p_source is required' using errcode = '22004';
  end if;

  if btrim(coalesce(p_source_url, '')) = '' then
    raise exception 'p_source_url is required' using errcode = '22004';
  end if;

  if btrim(coalesce(p_licence, '')) = '' then
    raise exception 'p_licence is required' using errcode = '22004';
  end if;

  select coalesce(max(sort_order) + 1, 0)
  into v_sort_order
  from public.place_images
  where place_id = p_place_id;

  insert into public.place_images (
    place_id,
    sort_order,
    image_url,
    thumbnail_url,
    source,
    source_url,
    licence,
    licence_url,
    attribution,
    external_id
  )
  values (
    p_place_id,
    v_sort_order,
    btrim(p_image_url),
    btrim(p_thumbnail_url),
    btrim(p_source),
    btrim(p_source_url),
    btrim(p_licence),
    nullif(btrim(p_licence_url), ''),
    nullif(btrim(p_attribution), ''),
    'dashboard:' || gen_random_uuid()::text
  )
  returning * into v_image;

  return v_image;
end;
$$;

revoke all on function public.add_place_image_dashboard_entry(
  uuid, text, text, text, text, text, text, text
) from public;
grant execute on function public.add_place_image_dashboard_entry(
  uuid, text, text, text, text, text, text, text
) to authenticated;

create or replace function public.update_place_image_dashboard_entry(
  p_image_id uuid,
  p_image_url text,
  p_thumbnail_url text,
  p_source text,
  p_source_url text,
  p_licence text,
  p_licence_url text,
  p_attribution text
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

  if btrim(coalesce(p_image_url, '')) = '' then
    raise exception 'p_image_url is required' using errcode = '22004';
  end if;

  if btrim(coalesce(p_thumbnail_url, '')) = '' then
    raise exception 'p_thumbnail_url is required' using errcode = '22004';
  end if;

  if btrim(coalesce(p_source, '')) = '' then
    raise exception 'p_source is required' using errcode = '22004';
  end if;

  if btrim(coalesce(p_source_url, '')) = '' then
    raise exception 'p_source_url is required' using errcode = '22004';
  end if;

  if btrim(coalesce(p_licence, '')) = '' then
    raise exception 'p_licence is required' using errcode = '22004';
  end if;

  update public.place_images
  set
    image_url = btrim(p_image_url),
    thumbnail_url = btrim(p_thumbnail_url),
    source = btrim(p_source),
    source_url = btrim(p_source_url),
    licence = btrim(p_licence),
    licence_url = nullif(btrim(p_licence_url), ''),
    attribution = nullif(btrim(p_attribution), '')
  where id = p_image_id
  returning * into v_image;

  if not found then
    raise exception 'Place image % was not found', p_image_id using errcode = 'P0002';
  end if;

  return v_image;
end;
$$;

revoke all on function public.update_place_image_dashboard_entry(
  uuid, text, text, text, text, text, text, text
) from public;
grant execute on function public.update_place_image_dashboard_entry(
  uuid, text, text, text, text, text, text, text
) to authenticated;

create or replace function public.reorder_place_images_dashboard(
  p_place_id uuid,
  p_image_ids uuid[]
)
returns setof public.place_images
language plpgsql
security definer
set search_path = public
as $$
declare
  v_role public.admin_role;
  v_expected_count integer;
  v_actual_count integer;
  v_total_count integer;
  v_image_id uuid;
  v_position integer;
begin
  v_role := public.current_admin_role();
  if v_role not in ('owner', 'admin', 'editor') then
    raise exception 'Place image management requires owner, admin, or editor access'
      using errcode = '42501';
  end if;

  if p_place_id is null then
    raise exception 'p_place_id is required' using errcode = '22004';
  end if;

  if p_image_ids is null or array_length(p_image_ids, 1) is null then
    raise exception 'p_image_ids must contain at least one image id'
      using errcode = '22004';
  end if;

  v_expected_count := array_length(p_image_ids, 1);

  select count(*) into v_actual_count
  from public.place_images
  where place_id = p_place_id
    and id = any (p_image_ids);

  select count(*) into v_total_count
  from public.place_images
  where place_id = p_place_id;

  if v_actual_count <> v_expected_count or v_expected_count <> v_total_count then
    raise exception 'p_image_ids must match exactly the images on this place'
      using errcode = '22023';
  end if;

  v_position := 0;
  foreach v_image_id in array p_image_ids loop
    update public.place_images
    set sort_order = v_position
    where id = v_image_id
      and place_id = p_place_id;

    v_position := v_position + 1;
  end loop;

  return query
    select * from public.place_images
    where place_id = p_place_id
    order by sort_order;
end;
$$;

revoke all on function public.reorder_place_images_dashboard(uuid, uuid[])
  from public;
grant execute on function public.reorder_place_images_dashboard(uuid, uuid[])
  to authenticated;
