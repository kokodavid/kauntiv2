-- Promoted / advertised place placements.
--
-- `places` stays the editorial source of truth for a destination. A paid
-- placement is a separate, auditable record so we can show an AD disclosure,
-- expire campaigns, and remove a promotion without deleting or rewriting the
-- underlying place.

create table if not exists public.place_promotions (
  id uuid primary key default gen_random_uuid(),
  place_id uuid not null references public.places (id) on delete cascade,
  disclosure_label text not null default 'AD',
  sponsor_name text not null,
  sponsor_url text,
  campaign_name text,
  placement text not null default 'places_to_see'
    check (placement in (
      'places_to_see',
      'map_pin',
      'for_you',
      'county_detail',
      'search'
    )),
  priority integer not null default 0,
  starts_at timestamptz not null default now(),
  ends_at timestamptz,
  deactivated_at timestamptz,
  created_by uuid references auth.users (id),
  updated_by uuid references auth.users (id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (btrim(disclosure_label) <> ''),
  check (btrim(sponsor_name) <> ''),
  check (ends_at is null or ends_at > starts_at)
);

create unique index if not exists place_promotions_one_active_placement_idx
  on public.place_promotions (place_id, placement)
  where deactivated_at is null;

create index if not exists place_promotions_place_id_idx
  on public.place_promotions (place_id);

create index if not exists place_promotions_active_window_idx
  on public.place_promotions (placement, starts_at, ends_at, priority)
  where deactivated_at is null;

comment on table public.place_promotions is
  'Paid/promoted place placements. Active rows require an AD disclosure in client UI.';

comment on column public.place_promotions.disclosure_label is
  'Short UI label for the paid placement, normally AD.';

comment on column public.place_promotions.placement is
  'Surface where the promotion may appear. One active promotion per place and placement.';

comment on column public.place_promotions.priority is
  'Higher values sort first within a promoted placement surface.';

alter table public.place_promotions enable row level security;

create policy "Anyone signed in can read active place promotions"
  on public.place_promotions
  for select
  to authenticated
  using (
    deactivated_at is null
    and starts_at <= now()
    and (ends_at is null or ends_at > now())
  );

create policy "Dashboard admins can read all place promotions"
  on public.place_promotions
  for select
  to authenticated
  using (public.current_admin_role() in ('owner', 'admin', 'editor'));

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
      and placement = v_placement
      and deactivated_at is null
    returning * into v_promotion;

    if not found then
      raise exception 'Active promotion for place % and placement % was not found',
        p_place_id,
        v_placement
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
  on conflict (place_id, placement)
    where deactivated_at is null
  do update set
    disclosure_label = excluded.disclosure_label,
    sponsor_name = excluded.sponsor_name,
    sponsor_url = excluded.sponsor_url,
    campaign_name = excluded.campaign_name,
    priority = excluded.priority,
    starts_at = excluded.starts_at,
    ends_at = excluded.ends_at,
    updated_by = auth.uid(),
    updated_at = v_now
  returning * into v_promotion;

  return v_promotion;
end;
$$;

revoke all on function public.set_place_promotion_dashboard(
  uuid,
  boolean,
  text,
  text,
  text,
  text,
  integer,
  timestamptz,
  timestamptz,
  text
) from public;

grant execute on function public.set_place_promotion_dashboard(
  uuid,
  boolean,
  text,
  text,
  text,
  text,
  integer,
  timestamptz,
  timestamptz,
  text
) to authenticated;
