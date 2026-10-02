-- Trip media: a photo captured while actively recording a Trip. Unlike
-- place-images (a shared admin dashboard bucket), this is per-user data:
-- a private bucket with folder-owner RLS (storage.foldername), mirroring
-- how `journeys`/`journey_points` are owner-only via table RLS rather
-- than a security-definer RPC -- binary uploads aren't practical through
-- a Postgres function, so the client writes directly here, governed by
-- RLS on both the bucket and the `journey_media` table.
--
-- Objects are stored at `<user_id>/<journey_id>/<media_id>.<ext>`, so the
-- folder-owner check is just "the first path segment is auth.uid()".
insert into storage.buckets (id, name, public)
values ('journey-media', 'journey-media', false)
on conflict (id) do update set public = false;

create policy "Users manage their own Trip media objects"
  on storage.objects
  for all
  to authenticated
  using (
    bucket_id = 'journey-media'
    and (storage.foldername(name))[1] = auth.uid()::text
  )
  with check (
    bucket_id = 'journey-media'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

-- The row per captured photo: the journey it belongs to, where it lives
-- in Storage, and where/when it was taken. No RPC for this one (see
-- above) -- ownership is enforced by RLS alone, and the journey_id
-- reference means media can't outlive its Trip.
create table public.journey_media (
  id uuid primary key default gen_random_uuid(),
  journey_id uuid not null references public.journeys (id) on delete cascade,
  user_id uuid not null references auth.users (id) on delete cascade,
  storage_path text not null unique,
  captured_at timestamptz not null,
  latitude double precision,
  longitude double precision,
  created_at timestamptz not null default now()
);

create index journey_media_journey_id_idx on public.journey_media (journey_id);

alter table public.journey_media enable row level security;

create policy "Users manage their own Trip media rows"
  on public.journey_media
  for all
  to authenticated
  using (user_id = auth.uid())
  with check (
    user_id = auth.uid()
    and exists (
      select 1 from public.journeys j
      where j.id = journey_id and j.user_id = auth.uid()
    )
  );
