set search_path = extensions, public;

-- Dashboard control of interests.
--
-- Owners and admins add, rename, reorder, hide and re-link interests through
-- these functions only (the tables stay read-only for the app). Icons: an
-- admin picks a name from the app's icon list, or uploads a one-colour SVG
-- or PNG to the interest-icons bucket and the app shows that instead.
-- Run after 20261018130000_interests_table.sql. Dev before prod.

-- 1. Icon bucket --------------------------------------------------------------
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'interest-icons', 'interest-icons', true, 262144,
  array['image/svg+xml', 'image/png']
)
on conflict (id) do update
  set public = true,
      file_size_limit = excluded.file_size_limit,
      allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists "Dashboard admins can upload interest icons" on storage.objects;
create policy "Dashboard admins can upload interest icons"
  on storage.objects for insert to authenticated
  with check (
    bucket_id = 'interest-icons'
    and public.current_admin_role() in ('owner', 'admin')
  );

drop policy if exists "Dashboard admins can update interest icons" on storage.objects;
create policy "Dashboard admins can update interest icons"
  on storage.objects for update to authenticated
  using (
    bucket_id = 'interest-icons'
    and public.current_admin_role() in ('owner', 'admin')
  );

drop policy if exists "Dashboard admins can delete interest icons" on storage.objects;
create policy "Dashboard admins can delete interest icons"
  on storage.objects for delete to authenticated
  using (
    bucket_id = 'interest-icons'
    and public.current_admin_role() in ('owner', 'admin')
  );

-- 2. Save an interest -----------------------------------------------------------
create or replace function public.save_interest(
  p_key text,
  p_label text,
  p_short_name text,
  p_icon_name text,
  p_icon_url text,
  p_sort_order integer,
  p_active boolean
)
returns public.interests
language plpgsql
security definer
set search_path = public
as $$
declare
  v_role public.admin_role := public.current_admin_role();
  v_key text := lower(btrim(p_key));
  v_label text := btrim(p_label);
  v_url text := nullif(btrim(p_icon_url), '');
  v_row public.interests;
begin
  if v_role is null or v_role not in ('owner', 'admin') then
    raise exception 'Editing interests requires owner or admin access'
      using errcode = '42501';
  end if;
  if v_key is null or v_key !~ '^[a-z][a-z_]*[a-z]$' then
    raise exception 'Key must be lower-case letters and underscores'
      using errcode = '22023';
  end if;
  if v_label is null or v_label = '' or length(v_label) > 60 then
    raise exception 'Label is required (60 characters at most)'
      using errcode = '22023';
  end if;
  if v_url is not null and v_url !~ '^https://' then
    raise exception 'Icon image must be an https link'
      using errcode = '22023';
  end if;

  insert into public.interests
    (key, label, short_name, icon_name, icon_url, sort_order, active)
  values (
    v_key,
    v_label,
    coalesce(nullif(btrim(p_short_name), ''), lower(v_label)),
    coalesce(nullif(btrim(p_icon_name), ''), 'place'),
    v_url,
    coalesce(p_sort_order, 100),
    coalesce(p_active, true)
  )
  on conflict (key) do update set
    label = excluded.label,
    short_name = excluded.short_name,
    icon_name = excluded.icon_name,
    icon_url = excluded.icon_url,
    sort_order = excluded.sort_order,
    active = excluded.active
  returning * into v_row;

  return v_row;
end;
$$;

revoke execute on function public.save_interest(text, text, text, text, text, integer, boolean) from public;
grant execute on function public.save_interest(text, text, text, text, text, integer, boolean) to authenticated;

-- 3. Replace an interest's place-type links -----------------------------------------
-- p_links: [{"place_type": "hike", "is_primary": true, "county_scope": "any"}]
create or replace function public.set_interest_types(
  p_key text,
  p_links jsonb
)
returns integer
language plpgsql
security definer
set search_path = public
as $$
declare
  v_role public.admin_role := public.current_admin_role();
  v_count integer;
begin
  if v_role is null or v_role not in ('owner', 'admin') then
    raise exception 'Editing interests requires owner or admin access'
      using errcode = '42501';
  end if;
  if not exists (select 1 from public.interests where key = p_key) then
    raise exception 'Unknown interest %', p_key using errcode = 'P0002';
  end if;
  if p_links is null or jsonb_typeof(p_links) <> 'array' then
    raise exception 'Links must be a list' using errcode = '22023';
  end if;
  if exists (
    select 1 from jsonb_to_recordset(p_links)
      as l(place_type text, is_primary boolean, county_scope text)
    where l.place_type is null
       or l.place_type not in (select key from public.place_types)
       or coalesce(l.county_scope, 'any') not in ('any', 'coastal', 'inland')
  ) then
    raise exception 'Each link needs a known place type and a valid county scope'
      using errcode = '22023';
  end if;

  delete from public.interest_place_types where interest_key = p_key;

  insert into public.interest_place_types
    (interest_key, place_type, is_primary, county_scope)
  select distinct on (l.place_type)
         p_key, l.place_type, coalesce(l.is_primary, false),
         coalesce(l.county_scope, 'any')
  from jsonb_to_recordset(p_links)
    as l(place_type text, is_primary boolean, county_scope text);

  get diagnostics v_count = row_count;
  return v_count;
end;
$$;

revoke execute on function public.set_interest_types(text, jsonb) from public;
grant execute on function public.set_interest_types(text, jsonb) to authenticated;
