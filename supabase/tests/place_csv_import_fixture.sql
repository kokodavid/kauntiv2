-- Isolated test schema; do not run against a live database.
create role anon;
create role authenticated;
create table public.counties(id smallint primary key);
insert into public.counties values(47),(22);
create table public.place_types(key text primary key,active boolean);
insert into public.place_types values('park',true),('stay',true),('retired',false);
create table public.places(
 id uuid primary key default gen_random_uuid(),county_id smallint,name text,type text,
 summary text,description text,source text,source_url text,licence text,last_verified_at date,
 lat double precision,lng double precision,external_id text,status text default 'draft',reviewed_at timestamptz,
 visit_duration_minutes integer,archived_at timestamptz,
 unique(source,external_id)
);
create function public.current_admin_role() returns text language sql as $$select current_setting('test.role',true)$$;
create function public.resolve_place_type(text) returns text language sql as $$select key from public.place_types where key=lower(btrim($1))$$;
create function public.create_place_dashboard_entry(smallint,text,text,text,text,text,text,text,date,double precision,double precision)
returns public.places language sql as $$
 insert into public.places(county_id,name,type,summary,description,source,source_url,licence,last_verified_at,lat,lng)
 values($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11) returning *;
$$;
