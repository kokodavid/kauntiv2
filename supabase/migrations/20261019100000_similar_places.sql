-- Duplicate checks for the dashboard: one matcher that compares a name and
-- (optionally) a pin against every place, live or not.
--
-- A place matches when
--   * its name reads the same once normalised (case, punctuation, Mt/Mount,
--     word order, "National Park" and similar filler are ignored),
--   * one name's words are all inside the other ("Karura" in "Karura Forest"),
--   * the names are spelled almost alike (trigram similarity), or
--   * it sits within the radius of the given pin, whatever it is called.
-- Drafts, needs-review and archived places are included on purpose: the
-- admin should see them even though the app does not.

create extension if not exists pg_trgm with schema extensions;

-- 1. Name key ---------------------------------------------------------------
-- "Mt. Kulal" and "Mount Kulal" -> "kulal mount"; words are sorted so
-- "Lake Ol Bolossat" and "Ol Bolossat Lake" give the same key.
create or replace function public.place_name_key(p_name text)
returns text
language sql
immutable
set search_path = public
as $$
  select coalesce(string_agg(w, ' ' order by w), '')
  from (
    select case t when 'mt' then 'mount' when 'st' then 'saint' else t end as w
    from unnest(
      regexp_split_to_array(
        regexp_replace(
          regexp_replace(lower(coalesce(p_name, '')), '[''’`]', '', 'g'),
          '[^a-z0-9]+', ' ', 'g'
        ),
        '\s+'
      )
    ) as t
    where t <> ''
      and t not in ('the', 'of', 'and', 'national', 'park', 'reserve', 'kenya')
  ) words;
$$;

-- 2. Core matcher (service role only) ----------------------------------------
create or replace function public.place_similar_core(
  p_name text,
  p_lat double precision default null,
  p_lng double precision default null,
  p_radius_m integer default 300,
  p_exclude uuid default null
)
returns table (
  id uuid,
  name text,
  type text,
  county_id smallint,
  county_name text,
  status text,
  archived boolean,
  lat double precision,
  lng double precision,
  distance_m integer,
  reason text,
  score real
)
language sql
stable
security definer
set search_path = public, extensions
as $$
  with q as (
    select
      public.place_name_key(p_name) as k,
      string_to_array(public.place_name_key(p_name), ' ') as toks
  ),
  c as (
    select
      p.id, p.name, p.type, p.county_id, co.name as county_name, p.status,
      (p.archived_at is not null) as archived, p.lat, p.lng,
      public.place_name_key(p.name) as k,
      case
        when p_lat is not null and p_lng is not null
          and p.lat is not null and p.lng is not null
        then (
          2 * 6371000 * asin(least(1, sqrt(
            power(sin(radians(p.lat - p_lat) / 2), 2)
            + cos(radians(p_lat)) * cos(radians(p.lat))
              * power(sin(radians(p.lng - p_lng) / 2), 2)
          )))
        )::integer
      end as dist
    from public.places p
    left join public.counties co on co.id = p.county_id
    where p.id is distinct from p_exclude
  ),
  m as (
    select
      c.*,
      (length(q.k) >= 3 and c.k = q.k) as same_key,
      (
        length(q.k) >= 3 and c.k <> ''
        and (
          string_to_array(c.k, ' ') <@ q.toks
          or q.toks <@ string_to_array(c.k, ' ')
        )
      ) as subset,
      case when length(q.k) >= 3 and c.k <> ''
        then similarity(c.k, q.k) else 0 end as sim
    from c, q
  ),
  scored as (
    select
      m.*,
      (m.same_key or m.subset or m.sim >= 0.55) as name_hit,
      (m.dist is not null and m.dist <= greatest(p_radius_m, 0)) as near
    from m
  )
  select
    s.id, s.name, s.type, s.county_id, s.county_name, s.status, s.archived,
    s.lat, s.lng, s.dist,
    case
      when s.name_hit and s.near then 'both'
      when s.name_hit then 'name'
      else 'near'
    end,
    (case
      when s.same_key and s.near then 1.0
      when s.same_key then 0.95
      when s.name_hit and s.near then 0.9
      when s.subset then 0.7
      when s.sim >= 0.55 then s.sim
      else 0.6
    end)::real
  from scored s
  where s.name_hit or s.near
  order by 12 desc, s.dist asc nulls last, s.name
  limit 8;
$$;

revoke all on function public.place_similar_core(
  text, double precision, double precision, integer, uuid
) from public, anon, authenticated;
grant execute on function public.place_similar_core(
  text, double precision, double precision, integer, uuid
) to service_role;

-- 3. Dashboard entry point ---------------------------------------------------
-- Owner, admin and editor only. Pass p_exclude when checking an existing
-- place so it does not match itself.
create or replace function public.find_similar_places_dashboard(
  p_name text default null,
  p_lat double precision default null,
  p_lng double precision default null,
  p_exclude uuid default null
)
returns table (
  id uuid,
  name text,
  type text,
  county_id smallint,
  county_name text,
  status text,
  archived boolean,
  lat double precision,
  lng double precision,
  distance_m integer,
  reason text,
  score real
)
language plpgsql
stable
security definer
set search_path = public
as $$
begin
  if coalesce(
    public.current_admin_role() in ('owner', 'admin', 'editor'),
    false
  ) is not true then
    raise exception 'Dashboard access required' using errcode = '42501';
  end if;

  return query
  select s.*
  from public.place_similar_core(p_name, p_lat, p_lng, 300, p_exclude) s;
end;
$$;

revoke all on function public.find_similar_places_dashboard(
  text, double precision, double precision, uuid
) from public, anon;
grant execute on function public.find_similar_places_dashboard(
  text, double precision, double precision, uuid
) to authenticated;
