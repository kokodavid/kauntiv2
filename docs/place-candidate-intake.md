# Place Candidate Intake

Production has two distinct paths for new place data:

- `public.places` is visible to signed-in app users and only receives a selected
  Dev place when its public profile is ready.
- `public.place_candidates` is an admin-only review queue. It is not readable
  through app RLS and is where incomplete or non-portable records remain.

Dev is never changed by this process. A selected record is copied, not moved.

## Public-readiness rules

The familiar profile score remains based on three fields:

1. A non-empty summary.
2. Coordinates.
3. At least one image row.

The import additionally blocks publication when the record has no source, or
when an image URL points at Supabase Storage. Storage objects are not copied by
this intake tool; keeping such a record in the queue prevents Production from
silently depending on Dev Storage.

## Selected Dev imports

Create a local, untracked text file with one Dev `places.id` UUID per line:

```text
# places-to-import.txt
469a1692-e0af-4266-a65d-92328d2b0dde
```

Set the usual Dev and Production Supabase URL and service-role environment
variables, then inspect the route before writing anything:

```bash
python3 tools/import_selected_places.py \
  --place-ids-file /secure/path/places-to-import.txt
```

After reviewing the output, perform the copy:

```bash
python3 tools/import_selected_places.py \
  --place-ids-file /secure/path/places-to-import.txt \
  --apply
```

The importer is resumable. Retrying does not duplicate a public place, candidate
record, or image row. It does not overwrite a candidate after an admin has
rejected or published it.

## Future scrapers

Scrapers must write candidate records only. They must never insert directly into
`public.places`; an editor reviews and publishes a candidate through the
dashboard once its content, location, image rights, and source are confirmed.
