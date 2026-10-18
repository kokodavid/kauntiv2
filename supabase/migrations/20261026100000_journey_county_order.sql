-- The order a Journey crossed its counties (0 = first entered), so the
-- trip card and share image can list them start to finish instead of in
-- whatever order Postgres returns the rows.
--
-- Null on trips uploaded before this; the app falls back to county code
-- for those until they are backfilled (the app computes the order from
-- the saved route points, since the boundaries live on the phone).
alter table public.journey_counties
  add column if not exists position smallint;

-- Called by the app right after upload (and by the backfill). Owner only;
-- county ids not already on the Journey are ignored.
create or replace function public.set_journey_county_order(
  p_journey_id uuid,
  p_county_ids integer[]
)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if auth.uid() is null then
    raise exception 'Not signed in' using errcode = '42501';
  end if;

  update public.journey_counties jc
  set position = (o.ordinality - 1)::smallint
  from unnest(p_county_ids) with ordinality as o(county_id, ordinality)
  where jc.journey_id = p_journey_id
    and jc.user_id = auth.uid()
    and jc.county_id = o.county_id;
end;
$$;

revoke execute on function public.set_journey_county_order(uuid, integer[])
  from public, anon;
grant execute on function public.set_journey_county_order(uuid, integer[])
  to authenticated;
