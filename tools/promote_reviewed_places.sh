#!/usr/bin/env bash

# Promote explicitly reviewed place content from the linked dev project to the
# linked production project. It intentionally does not move promotions, user
# content, storage objects, or unreviewed rows.

set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  tools/promote_reviewed_places.sh \
    --dev-db-url "$KAUNTI_DEV_DB_URL" \
    --prod-db-url "$KAUNTI_PROD_DB_URL" [--apply]

Without --apply, the script only prints the reviewed Dev places that would be
promoted. --apply writes those places and their attached place_images to
Production.

The database URLs are intentionally not read from project files. Set them in
your shell from Supabase Connect details; never commit them.
EOF
}

dev_db_url="${KAUNTI_DEV_DB_URL:-}"
prod_db_url="${KAUNTI_PROD_DB_URL:-}"
apply=false

while (($# > 0)); do
  case "$1" in
    --dev-db-url)
      dev_db_url="${2:-}"
      shift 2
      ;;
    --prod-db-url)
      prod_db_url="${2:-}"
      shift 2
      ;;
    --apply)
      apply=true
      shift
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      printf 'Unknown argument: %s\n' "$1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

if [[ -z "$dev_db_url" || -z "$prod_db_url" ]]; then
  usage >&2
  exit 2
fi

for command in jq supabase; do
  command -v "$command" >/dev/null || {
    printf 'Required command not found: %s\n' "$command" >&2
    exit 1
  }
done

if [[ "$dev_db_url" == "$prod_db_url" ]]; then
  printf 'Dev and Production use the same database URL. Aborting.\n' >&2
  exit 1
fi

source_sql=$(cat <<'SQL'
set search_path = extensions, public;

with reviewed_places as (
  select
    p.id,
    p.county_id,
    p.name,
    p.type,
    p.summary,
    p.description,
    st_y(p.location) as lat,
    st_x(p.location) as lng,
    p.source,
    p.source_url,
    p.licence,
    p.external_id,
    p.last_verified_at,
    p.content_origin,
    p.reviewed_at
  from public.places p
  where p.reviewed_at is not null
), reviewed_images as (
  select
    image.id,
    image.place_id,
    image.sort_order,
    image.image_url,
    image.thumbnail_url,
    image.width,
    image.height,
    image.source,
    image.source_url,
    image.licence,
    image.licence_url,
    image.attribution,
    image.external_id,
    image.last_verified_at
  from public.place_images image
  join reviewed_places place on place.id = image.place_id
)
select jsonb_build_object(
  'places', coalesce(
    (select jsonb_agg(to_jsonb(place) order by place.county_id, place.name)
      from reviewed_places place),
    '[]'::jsonb
  ),
  'images', coalesce(
    (select jsonb_agg(to_jsonb(image) order by image.place_id, image.sort_order)
      from reviewed_images image),
    '[]'::jsonb
  )
) as payload;
SQL
)

source_result="$(mktemp)"
target_sql_file="$(mktemp)"
trap 'rm -f "$source_result" "$target_sql_file"' EXIT

supabase db query --db-url "$dev_db_url" --output-format json "$source_sql" >"$source_result"

payload="$(jq -cer '.rows[0].payload | if type == "string" then fromjson else . end' "$source_result")"
place_count="$(jq '.places | length' <<<"$payload")"
image_count="$(jq '.images | length' <<<"$payload")"

printf 'Dev and Production database URLs are configured separately.\n'
printf 'Reviewed places: %s\nAttached images: %s\n' "$place_count" "$image_count"
jq -r '.places[] | "- \(.name) (county \(.county_id), reviewed \(.reviewed_at))"' <<<"$payload"

if [[ "$apply" != true ]]; then
  printf '\nDry run only. Re-run with --apply after reviewing this list.\n'
  exit 0
fi

if [[ "$place_count" == 0 ]]; then
  printf 'No reviewed places to promote. Production was not changed.\n'
  exit 0
fi

payload_base64="$(printf '%s' "$payload" | base64 | tr -d '\n')"

cat >"$target_sql_file" <<SQL
begin;
set search_path = extensions, public;

with payload as (
  select convert_from(decode('$payload_base64', 'base64'), 'utf8')::jsonb as data
), place_rows as (
  select *
  from jsonb_to_recordset((select data -> 'places' from payload)) as place(
    id uuid,
    county_id smallint,
    name text,
    type text,
    summary text,
    description text,
    lat double precision,
    lng double precision,
    source text,
    source_url text,
    licence text,
    external_id text,
    last_verified_at date,
    content_origin text,
    reviewed_at timestamptz
  )
), imported_places as (
  insert into public.places (
    id,
    county_id,
    name,
    type,
    summary,
    description,
    location,
    source,
    source_url,
    licence,
    external_id,
    last_verified_at,
    content_origin,
    reviewed_at
  )
  select
    id,
    county_id,
    name,
    type,
    summary,
    description,
    st_setsrid(st_makepoint(lng, lat), 4326),
    source,
    source_url,
    licence,
    external_id,
    last_verified_at,
    content_origin,
    reviewed_at
  from place_rows
  on conflict (id) do update set
    county_id = excluded.county_id,
    name = excluded.name,
    type = excluded.type,
    summary = excluded.summary,
    description = excluded.description,
    location = excluded.location,
    source = excluded.source,
    source_url = excluded.source_url,
    licence = excluded.licence,
    external_id = excluded.external_id,
    last_verified_at = excluded.last_verified_at,
    content_origin = excluded.content_origin,
    reviewed_at = excluded.reviewed_at
  returning id
), image_rows as (
  select *
  from jsonb_to_recordset((select data -> 'images' from payload)) as image(
    id uuid,
    place_id uuid,
    sort_order integer,
    image_url text,
    thumbnail_url text,
    width integer,
    height integer,
    source text,
    source_url text,
    licence text,
    licence_url text,
    attribution text,
    external_id text,
    last_verified_at date
  )
)
insert into public.place_images (
  id,
  place_id,
  sort_order,
  image_url,
  thumbnail_url,
  width,
  height,
  source,
  source_url,
  licence,
  licence_url,
  attribution,
  external_id,
  last_verified_at
)
select
  id,
  place_id,
  sort_order,
  image_url,
  thumbnail_url,
  width,
  height,
  source,
  source_url,
  licence,
  licence_url,
  attribution,
  external_id,
  last_verified_at
from image_rows
where exists (
  select 1 from imported_places place where place.id = image_rows.place_id
)
on conflict (id) do update set
  place_id = excluded.place_id,
  sort_order = excluded.sort_order,
  image_url = excluded.image_url,
  thumbnail_url = excluded.thumbnail_url,
  width = excluded.width,
  height = excluded.height,
  source = excluded.source,
  source_url = excluded.source_url,
  licence = excluded.licence,
  licence_url = excluded.licence_url,
  attribution = excluded.attribution,
  external_id = excluded.external_id,
  last_verified_at = excluded.last_verified_at;

commit;
SQL

supabase db query --db-url "$prod_db_url" --file "$target_sql_file"

printf '\nPromotion completed. Verify the production counts and place details before migrating user data.\n'
