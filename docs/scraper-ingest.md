# Scraper ingest

Scraped places enter through one narrow path and are never written to
`public.places` directly.

```
worker (GitHub Actions)  ->  Edge Function ingest-place-candidates  ->  service-role RPCs  ->  place_candidates
                                                                                              (human review in the dashboard)
```

## Database (`20261007110000_add_scraper_foundation.sql`)

- `scrape_sources` registry (slug, kind, `enabled`, config, `checkpoint`) and
  `scrape_runs` log. A partial unique index allows one `running` run per
  source, and a run that never reports back is closed as failed after 3 hours.
- `place_candidates` gains `origin` (`dev_import` or `scraper`),
  `scrape_source_id`, `source_item_key` and `content_hash`. A unique index on
  `(scrape_source_id, source_item_key)` is the authoritative dedupe; the old
  Dev-import identity (`source_place_id`) is kept separate and the two are
  mutually exclusive by check constraint.
- Dedupe happens in the database: same source item, same place (source +
  external id, same name in the county, or same name within 150 m), or the same
  name as an existing candidate. A place within 100 m under a different name
  adds a `possible duplicate` blocker.
- Coordinates are required. The county is derived from the county polygons; if
  the worker supplies `county_id` and it disagrees, the item is rejected.
- Scraper updates never overwrite an editor's work. An untouched candidate is
  refreshed in place; one a person has edited gets a pending row in
  `place_candidate_revisions` (a newer change supersedes an older pending one).
  Published or rejected candidates are left alone.
- Candidate images keep their remote source, licence and attribution; images
  without a licence and attribution are dropped. Approved copies will live in
  the private `place-candidate-staging` bucket (no policies, service role only).
- `publish_place_candidate_dashboard` refuses `origin = 'scraper'` until the
  reviewed-asset publish workflow replaces that guard.

## Edge Function

`supabase/functions/ingest-place-candidates` takes `POST` with header
`x-ingest-key` and one of:

| action | body |
| --- | --- |
| `start` | `{ source, triggered_by: 'schedule'\|'manual', dry_run }` -> `{ run_id, source, checkpoint }` |
| `items` | `{ run_id, items: [...] }` (max 100) -> `{ results: [{ key, outcome, ... }] }` |
| `finish` | `{ run_id, status: 'succeeded'\|'partial'\|'failed', checkpoint, error_summary }` |

An item is `{ key, name, type, lat, lng, summary?, description?, source?, source_url?,
licence?, external_id?, county_id?, images?: [{ key, remote_url, licence, attribution, ... }] }`.
Outcomes: `created`, `updated`, `unchanged`, `revision`, `duplicate`, `rejected`
(with `reason`), `skipped_reviewed`, `error`.

Deploy per environment, never committing the key:

```bash
supabase functions deploy ingest-place-candidates --no-verify-jwt --project-ref <ref>
supabase secrets set SCRAPER_INGEST_KEY="$SCRAPER_INGEST_KEY" --project-ref <ref>
```

Use a different key for Dev and Production.

## Wikidata Dev collector

`tools/collect_wikidata_places.py` is the first source adapter. It queries a
small allowlist of structured Wikidata place classes with Kenyan coordinates,
deduplicates repeated Wikidata items locally, and sends batches only to the
ingest function. The database remains authoritative for county assignment,
deduplication and every write.

It imports no images. Wikidata text fields are CC0, but image download,
private staging, editor approval and publication remain separate work.

`.github/workflows/wikidata-dev.yml` is intentionally manual and uses the
GitHub `dev` Environment. Configure only these Environment secrets:

- `DEV_SCRAPER_INGEST_URL` — the Dev `ingest-place-candidates` function URL.
- `DEV_SCRAPER_INGEST_KEY` — the dedicated Dev key, never a service-role key.

The workflow defaults to a 25-row dry run. A live Dev run requires an explicit
`dry_run=false` choice in the Actions UI, and still creates only dashboard
candidates. It does not have a schedule or any Production credentials.

## Not built yet

Additional source adapters, image staging and approval, the reviewed-asset
publish workflow, the dashboard scraper-runs and revision-diff screens, and
any scheduled or Production collector.
