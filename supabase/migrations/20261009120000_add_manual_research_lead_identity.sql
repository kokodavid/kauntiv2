-- A manually imported research lead has a discovery-page identity, not a
-- Dev place ID or a scraper item key. Keep all three origins constrained.

alter table public.place_candidates
  drop constraint if exists place_candidates_origin_check,
  add constraint place_candidates_origin_check
    check (origin in ('dev_import', 'scraper', 'research_lead'));

alter table public.place_candidates
  drop constraint if exists place_candidates_identity_check,
  add constraint place_candidates_identity_check check (
    (origin = 'dev_import'
      and source_place_id is not null
      and scrape_source_id is null
      and source_item_key is null
      and intake_key is null)
    or
    (origin = 'scraper'
      and source_place_id is null
      and scrape_source_id is not null
      and source_item_key is not null
      and intake_key is null)
    or
    (origin = 'research_lead'
      and source_place_id is null
      and scrape_source_id is null
      and source_item_key is null
      and intake_source is not null
      and intake_source_url is not null
      and intake_key is not null)
  );

create or replace function public.create_place_candidate_leads_dashboard(
  p_source_name text,
  p_source_url text,
  p_county_id smallint,
  p_names text[]
)
returns table (
  requested_name text,
  candidate_id uuid,
  outcome text,
  matched_name text
)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_role public.admin_role;
  v_source_name text := nullif(btrim(p_source_name), '');
  v_source_url text := nullif(btrim(p_source_url), '');
  v_name text;
  v_key text;
  v_existing uuid;
  v_existing_name text;
  v_candidate uuid;
  v_missing text[] := array['research', 'summary', 'coordinates', 'image'];
  v_blockers text[] := array['source'];
begin
  v_role := public.current_admin_role();
  if v_role not in ('owner', 'admin', 'editor') then
    raise exception 'Candidate intake requires owner, admin, or editor access'
      using errcode = '42501';
  end if;
  if v_source_name is null or v_source_url is null or v_source_url !~ '^https?://' then
    raise exception 'A source name and valid https URL are required' using errcode = '22023';
  end if;
  if p_county_id is null or not exists (select 1 from public.counties where id = p_county_id) then
    raise exception 'A valid county is required' using errcode = '22023';
  end if;
  if coalesce(cardinality(p_names), 0) not between 1 and 50 then
    raise exception 'Enter between 1 and 50 place names' using errcode = '22023';
  end if;

  for v_name in
    select distinct btrim(value)
    from unnest(p_names) value
    where length(btrim(value)) between 3 and 120
  loop
    v_key := md5(lower(v_source_url) || '|' || p_county_id::text || '|' || lower(v_name));

    select p.id, p.name into v_existing, v_existing_name
    from public.places p
    where p.county_id = p_county_id and lower(btrim(p.name)) = lower(v_name)
    limit 1;
    if v_existing is not null then
      return query select v_name, v_existing, 'already_published'::text, v_existing_name;
      continue;
    end if;

    select c.id, c.name into v_existing, v_existing_name
    from public.place_candidates c
    where c.county_id = p_county_id
      and lower(btrim(c.name)) = lower(v_name)
      and c.status in ('pending_review', 'published')
    limit 1;
    if v_existing is not null then
      return query select v_name, v_existing, 'already_queued'::text, v_existing_name;
      continue;
    end if;

    insert into public.place_candidates (
      origin, county_id, name, type, intake_source, intake_source_url, intake_key,
      research_status, completeness, missing_fields, publish_blockers
    ) values (
      'research_lead', p_county_id, v_name, 'place', v_source_name, v_source_url, v_key,
      'pending_research', 0, v_missing, v_blockers
    ) returning id into v_candidate;

    return query select v_name, v_candidate, 'created'::text, null::text;
  end loop;
end;
$$;

revoke all on function public.create_place_candidate_leads_dashboard(text, text, smallint, text[]) from public;
grant execute on function public.create_place_candidate_leads_dashboard(text, text, smallint, text[]) to authenticated;
