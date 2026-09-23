-- Dashboard county editing.
--
-- Keep county geometry and centroids out of the dashboard write path. Admin
-- users can update editorial/profile fields through this RPC only.

create or replace function public.update_county_dashboard_profile(
  p_county_id smallint,
  p_capital text,
  p_year_established smallint,
  p_population bigint,
  p_rarity_pct numeric,
  p_is_coastal boolean,
  p_highlight_image_url text,
  p_highlight_image_source text,
  p_highlight_image_source_url text,
  p_highlight_image_licence text,
  p_highlight_image_licence_url text,
  p_highlight_image_attribution text,
  p_highlight_image_last_verified_at date
)
returns public.counties
language plpgsql
security definer
set search_path = public
as $$
declare
  v_role public.admin_role;
  v_county public.counties;
begin
  v_role := public.current_admin_role();

  if v_role not in ('owner', 'admin', 'editor') then
    raise exception 'County editing requires owner, admin, or editor access'
      using errcode = '42501';
  end if;

  if p_county_id is null or p_county_id < 1 or p_county_id > 47 then
    raise exception 'County id must be between 1 and 47'
      using errcode = '22023';
  end if;

  if p_year_established is not null and (
    p_year_established < 1963 or p_year_established > extract(year from now())::smallint
  ) then
    raise exception 'Year established is outside the allowed range'
      using errcode = '22023';
  end if;

  if p_population is not null and p_population < 0 then
    raise exception 'Population cannot be negative'
      using errcode = '22023';
  end if;

  if p_rarity_pct is not null and (p_rarity_pct < 0 or p_rarity_pct > 100) then
    raise exception 'Rarity percent must be between 0 and 100'
      using errcode = '22023';
  end if;

  update public.counties
  set
    capital = nullif(btrim(p_capital), ''),
    year_established = p_year_established,
    population = p_population,
    rarity_pct = p_rarity_pct,
    is_coastal = coalesce(p_is_coastal, false),
    highlight_image_url = nullif(btrim(p_highlight_image_url), ''),
    highlight_image_source = nullif(btrim(p_highlight_image_source), ''),
    highlight_image_source_url = nullif(btrim(p_highlight_image_source_url), ''),
    highlight_image_licence = nullif(btrim(p_highlight_image_licence), ''),
    highlight_image_licence_url = nullif(btrim(p_highlight_image_licence_url), ''),
    highlight_image_attribution = nullif(btrim(p_highlight_image_attribution), ''),
    highlight_image_last_verified_at = p_highlight_image_last_verified_at
  where id = p_county_id
  returning * into v_county;

  if not found then
    raise exception 'County % was not found', p_county_id
      using errcode = 'P0002';
  end if;

  return v_county;
end;
$$;

revoke execute on function public.update_county_dashboard_profile(
  smallint,
  text,
  smallint,
  bigint,
  numeric,
  boolean,
  text,
  text,
  text,
  text,
  text,
  text,
  date
) from public;

grant execute on function public.update_county_dashboard_profile(
  smallint,
  text,
  smallint,
  bigint,
  numeric,
  boolean,
  text,
  text,
  text,
  text,
  text,
  text,
  date
) to authenticated;
