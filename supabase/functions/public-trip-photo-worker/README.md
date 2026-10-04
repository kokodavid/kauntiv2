# public-trip-photo-worker

Sanitizes photos that owners chose to show on a Public Trip. It claims one job
at a time through `list_public_trip_photo_jobs`, re-encodes the photo with every
piece of metadata removed (EXIF, GPS, XMP, IPTC, ICC), stores the copy in the
private `public-trip-media` bucket and reports back with
`complete_public_trip_photo` or `fail_public_trip_photo`. The database refuses a
report for a trip that was withdrawn or changed in the meantime, and the worker
then deletes its upload.

EXIF removal does not hide faces, number plates or addresses visible in the
picture. Moderators review the pixels.

## Limits it enforces

| Rule | Result |
|---|---|
| Source over 16 MB or over 52 megapixels | photo failed: "Photo is too large to publish" |
| PNG or WebP larger than 2560 px | photo failed: "Photo is too large to publish" (the app only uploads JPEG) |
| Not a JPEG, PNG or WebP | photo failed: "Unsupported photo format" |
| Output | JPEG, quality 82, longest side at most 2560 px, never resized: JPEGs are decoded at 1/2, 1/4 or 1/8 scale |
| Killed by the platform (CPU or memory) | retried after a 3 minute lease, failed after 3 attempts |

## Tests

```sh
cd supabase/functions/public-trip-photo-worker
deno test --allow-read --allow-env sanitize_test.ts
```

Fixtures are synthetic: a fake GPS position, device name and rotation tag.

## Deploy (dev first)

Requires the Supabase CLI (`brew install supabase/tap/supabase`, then
`supabase login`). From the repository root:

```sh
supabase functions deploy public-trip-photo-worker --no-verify-jwt --project-ref <dev-project-ref>
```

`--no-verify-jwt` is intentional: the function checks that the bearer token is
its own dedicated worker secret, which is stricter than a valid JWT.

Create the secret once (any random string of 32+ characters) and set it on the
function. Keep a copy for the Vault step below; never commit it.

```sh
WORKER_SECRET=$(openssl rand -hex 32)
supabase secrets set PUBLIC_TRIP_WORKER_SECRET="$WORKER_SECRET" --project-ref <dev-project-ref>
echo "$WORKER_SECRET"   # copy this into the Vault statement below
```

## Schedule (run once per project in the SQL editor)

Enable the `pg_cron` and `pg_net` extensions first. Store the worker secret
in Vault from the SQL editor; never commit it.

```sql
select vault.create_secret('<worker-secret>', 'public_trip_worker_key');

-- Drain the photo queue every minute (the function also chains itself).
select cron.schedule('public-trip-photo-worker', '* * * * *', $$
  select net.http_post(
    url := 'https://<project-ref>.supabase.co/functions/v1/public-trip-photo-worker',
    headers := jsonb_build_object('Authorization', 'Bearer ' ||
      (select decrypted_secret from vault.decrypted_secrets where name = 'public_trip_worker_key')))
$$);

-- Delete stored photos nothing references any more (older than an hour).
select cron.schedule('public-trip-photo-sweep', '17 3 * * *', $$
  select net.http_post(
    url := 'https://<project-ref>.supabase.co/functions/v1/public-trip-photo-worker?sweep=1',
    headers := jsonb_build_object('Authorization', 'Bearer ' ||
      (select decrypted_secret from vault.decrypted_secrets where name = 'public_trip_worker_key')))
$$);

-- Expired and superseded revisions.
select cron.schedule('public-trip-cleanup', '23 * * * *', 'select public.cleanup_public_trips()');
```

## CPU, measured on a real project

The first version resized with ImageMagick and ran out of CPU on real photos
("CPU Time exceeded", 2002 ms, on Supabase). A resize costs about 1.5 s in this
WASM build even for a 3 MP image. The worker now decodes JPEGs at a reduced
scale and does not resize. Local timings: about 0.45 s for a 2048 px photo,
about 0.5 s for 12 MP and about 0.7 s for 50 MP, at under 175 MB. Re-check the
function logs after deploying; the limit is 2 s CPU and 256 MB.
