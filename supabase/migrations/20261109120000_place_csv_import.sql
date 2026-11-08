-- CSV is parsed/previewed in the dashboard; the server validates every row.
-- One transaction per batch: no overwrite, no publishing, safe to retry.
create or replace function public.import_places_csv_dashboard(p_rows jsonb)
returns table(record_number integer, place_id uuid, name text, outcome text)
language plpgsql security definer set search_path = ''
as $$
declare
  r jsonb; n integer := 0; p public.places;
  v_source text; v_external text; v_name text; v_type text; v_county smallint;
  v_lat double precision; v_lng double precision; v_date date; v_duration integer;
  k text;
begin
  if coalesce(public.current_admin_role() in ('owner','admin','editor'),false) is not true then
    raise exception 'Owner, admin or editor access required' using errcode='42501';
  end if;
  if p_rows is null or jsonb_typeof(p_rows)<>'array' then
    raise exception 'Rows must be a JSON array' using errcode='22023';
  end if;
  if jsonb_array_length(p_rows) not between 1 and 200 or octet_length(p_rows::text)>1048576 then
    raise exception 'Import must contain 1 to 200 records and at most 1 MB' using errcode='22023';
  end if;
  -- Serialize CSV imports so two uploads cannot create the same named place.
  perform pg_advisory_xact_lock(hashtextextended('dashboard_csv_place_import',0));
  for r in select value from jsonb_array_elements(p_rows) loop
    n := n+1;
    begin
      if jsonb_typeof(r)<>'object' then raise exception 'Expected a place object'; end if;
      for k in select jsonb_object_keys(r) loop
        if k<>all(array['external_id','name','county_id','type','lat','lng','summary','description','source','source_url','licence','last_verified_at','visit_duration_minutes']) then
          raise exception 'Unsupported field: %',k;
        end if;
      end loop;
      foreach k in array array['external_id','name','type','source'] loop
        if jsonb_typeof(r->k) is distinct from 'string' or btrim(r->>k)='' then
          raise exception '% is required',k;
        end if;
      end loop;
      foreach k in array array['summary','description','source_url','licence','last_verified_at'] loop
        if r ? k and jsonb_typeof(r->k) not in ('string','null') then raise exception '% must be text',k; end if;
      end loop;
      v_source := btrim(r->>'source'); v_external := btrim(r->>'external_id');
      v_name := btrim(r->>'name'); v_type := public.resolve_place_type(r->>'type');
      if length(v_name)>200 or length(v_source)>200 or length(v_external)>200
        or length(coalesce(r->>'summary',''))>1000 or length(coalesce(r->>'description',''))>20000
        or length(coalesce(r->>'licence',''))>1000 or length(coalesce(r->>'source_url',''))>2048 then
        raise exception 'A text field exceeds the import length limit';
      end if;
      if v_type is null or not exists(select 1 from public.place_types t where t.key=v_type and t.active) then
        raise exception 'Unknown or inactive place type: %',r->>'type';
      end if;
      if jsonb_typeof(r->'county_id') is distinct from 'number' or (r->>'county_id')::numeric<>trunc((r->>'county_id')::numeric) then
        raise exception 'county_id must be an integer';
      end if;
      v_county := (r->>'county_id')::numeric::smallint;
      if not exists(select 1 from public.counties c where c.id=v_county) then raise exception 'Unknown county_id: %',v_county; end if;
      if jsonb_typeof(r->'lat') is distinct from 'number' or jsonb_typeof(r->'lng') is distinct from 'number' then
        raise exception 'lat and lng must be numbers';
      end if;
      v_lat := (r->>'lat')::double precision; v_lng := (r->>'lng')::double precision;
      if not(v_lat between -90 and 90) or not(v_lng between -180 and 180) then raise exception 'Coordinates out of range'; end if;
      if nullif(btrim(r->>'source_url'),'') is not null and btrim(r->>'source_url') !~* '^https?://[^[:space:]]+$' then
        raise exception 'source_url must be an HTTP(S) URL';
      end if;
      v_date := null;
      if nullif(btrim(r->>'last_verified_at'),'') is not null then
        if btrim(r->>'last_verified_at') !~ '^\d{4}-\d{2}-\d{2}$' then raise exception 'last_verified_at must use YYYY-MM-DD'; end if;
        v_date := (r->>'last_verified_at')::date;
        if v_date>current_date then raise exception 'Verification date cannot be in the future'; end if;
      end if;
      v_duration := null;
      if r->'visit_duration_minutes' is not null and r->'visit_duration_minutes'<>'null'::jsonb then
        if jsonb_typeof(r->'visit_duration_minutes')<>'number' or (r->>'visit_duration_minutes')::numeric<>trunc((r->>'visit_duration_minutes')::numeric) then
          raise exception 'visit_duration_minutes must be a positive integer';
        end if;
        v_duration := (r->>'visit_duration_minutes')::numeric::integer;
        if v_duration<=0 then raise exception 'visit_duration_minutes must be positive'; end if;
      end if;
      select x.* into p from public.places x
      where (x.source=v_source and x.external_id=v_external)
        or (x.county_id=v_county and lower(btrim(x.name))=lower(v_name))
      order by (x.source=v_source and x.external_id=v_external) desc nulls last,x.id limit 1;
      if found then
        record_number:=n;place_id:=p.id;name:=p.name;outcome:='skipped_existing';return next;
      else
        p := public.create_place_dashboard_entry(v_county,v_name,v_type,r->>'summary',r->>'description',
          v_source,r->>'source_url',r->>'licence',v_date,v_lat,v_lng);
        update public.places x set external_id=v_external,status='draft',reviewed_at=null,
          visit_duration_minutes=v_duration where x.id=p.id;
        record_number:=n;place_id:=p.id;name:=p.name;outcome:='created';return next;
      end if;
    exception when others then
      raise exception 'Record %: %',n,sqlerrm using errcode='22023';
    end;
  end loop;
end;
$$;
revoke all on function public.import_places_csv_dashboard(jsonb) from public,anon;
grant execute on function public.import_places_csv_dashboard(jsonb) to authenticated;
