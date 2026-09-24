-- Fix promoted-place edits so changing placement updates the same active AD
-- row instead of creating a second active promotion for the same place.
--
-- The first promotion migration keyed active rows by (place_id, placement).
-- That allowed a dashboard edit from "Places to See" to "For You" to create
-- two live AD rows for one place. Product rule: one active ad per place.

with ranked_active_promotions as (
  select
    id,
    row_number() over (
      partition by place_id
      order by created_at desc, updated_at desc, id desc
    ) as active_rank
  from public.place_promotions
  where deactivated_at is null
)
update public.place_promotions as promotion
set
  deactivated_at = now(),
  updated_at = now()
from ranked_active_promotions ranked
where promotion.id = ranked.id
  and ranked.active_rank > 1;

drop index if exists public.place_promotions_one_active_placement_idx;

create unique index if not exists place_promotions_one_active_place_idx
  on public.place_promotions (place_id)
  where deactivated_at is null;

comment on column public.place_promotions.placement is
  'Surface where the promotion may appear. A place may have only one active promotion row, so changing placement updates that active row.';

create or replace function public.set_place_promotion_dashboard(
  p_place_id uuid,
  p_promoted boolean,
  p_sponsor_name text default null,
  p_sponsor_url text default null,
  p_campaign_name text default null,
  p_placement text default 'places_to_see',
  p_priority integer default 0,
  p_starts_at timestamptz default null,
  p_ends_at timestamptz default null,
  p_disclosure_label text default 'AD'
)
returns public.place_promotions
language plpgsql
security definer
set search_path = public
as $$
declare
  v_role public.admin_role;
  v_promotion public.place_promotions;
  v_now timestamptz := now();
  v_placement text := coalesce(nullif(btrim(p_placement), ''), 'places_to_see');
  v_starts_at timestamptz := coalesce(p_starts_at, v_now);
begin
  v_role := public.current_admin_role();

  if v_role not in ('owner', 'admin', 'editor') then
    raise exception 'Place promotion changes require owner, admin, or editor access'
      using errcode = '42501';
  end if;

  if p_place_id is null then
    raise exception 'Place id is required'
      using errcode = '22023';
  end if;

  if not exists (select 1 from public.places where id = p_place_id) then
    raise exception 'Place % was not found', p_place_id
      using errcode = 'P0002';
  end if;

  if v_placement not in (
    'places_to_see',
    'map_pin',
    'for_you',
    'county_detail',
    'search'
  ) then
    raise exception 'Unsupported promotion placement: %', v_placement
      using errcode = '22023';
  end if;

  if not coalesce(p_promoted, false) then
    update public.place_promotions
    set
      deactivated_at = v_now,
      updated_by = auth.uid(),
      updated_at = v_now
    where place_id = p_place_id
      and deactivated_at is null
    returning * into v_promotion;

    if not found then
      raise exception 'Active promotion for place % was not found', p_place_id
        using errcode = 'P0002';
    end if;

    return v_promotion;
  end if;

  if nullif(btrim(p_sponsor_name), '') is null then
    raise exception 'Sponsor name is required for a promoted place'
      using errcode = '22023';
  end if;

  if nullif(btrim(p_disclosure_label), '') is null then
    raise exception 'Disclosure label is required for a promoted place'
      using errcode = '22023';
  end if;

  if p_ends_at is not null and p_ends_at <= v_starts_at then
    raise exception 'Promotion end time must be after start time'
      using errcode = '22023';
  end if;

  update public.place_promotions
  set
    disclosure_label = btrim(p_disclosure_label),
    sponsor_name = btrim(p_sponsor_name),
    sponsor_url = nullif(btrim(p_sponsor_url), ''),
    campaign_name = nullif(btrim(p_campaign_name), ''),
    placement = v_placement,
    priority = coalesce(p_priority, 0),
    starts_at = v_starts_at,
    ends_at = p_ends_at,
    updated_by = auth.uid(),
    updated_at = v_now
  where place_id = p_place_id
    and deactivated_at is null
  returning * into v_promotion;

  if found then
    return v_promotion;
  end if;

  insert into public.place_promotions (
    place_id,
    disclosure_label,
    sponsor_name,
    sponsor_url,
    campaign_name,
    placement,
    priority,
    starts_at,
    ends_at,
    created_by,
    updated_by
  )
  values (
    p_place_id,
    btrim(p_disclosure_label),
    btrim(p_sponsor_name),
    nullif(btrim(p_sponsor_url), ''),
    nullif(btrim(p_campaign_name), ''),
    v_placement,
    coalesce(p_priority, 0),
    v_starts_at,
    p_ends_at,
    auth.uid(),
    auth.uid()
  )
  returning * into v_promotion;

  return v_promotion;
end;
$$;
