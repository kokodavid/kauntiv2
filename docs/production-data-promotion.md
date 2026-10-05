# Production Data Promotion

Production schema migrations do not import development fixture content. Promote
editor-approved content separately and deliberately.

## Reviewed places

`reviewed_at is not null` is the only readiness gate for place promotion.
`content_origin` records provenance and must not be used as a readiness gate.

Set the database connection URLs in your shell from each project’s Supabase
**Connect** details. Keep them out of source control:

```bash
export KAUNTI_DEV_DB_URL='postgresql://...'
export KAUNTI_PROD_DB_URL='postgresql://...'
```

Use the dry run first:

```bash
tools/promote_reviewed_places.sh
```

After reviewing the printed set, repeat with `--apply`. The script copies
reviewed places and their `place_images`, preserves their UUIDs, and is safe to
run again for the same rows. It deliberately excludes promotions, user content,
storage objects, and every unreviewed place.

Verify the result in Production:

```sql
select
  p.name,
  c.name as county,
  p.reviewed_at,
  count(image.id) as image_count
from public.places p
join public.counties c on c.id = p.county_id
left join public.place_images image on image.place_id = p.id
group by p.id, p.name, c.name, p.reviewed_at
order by c.name, p.name;
```

Only promote user progress after its referenced places exist in Production.
