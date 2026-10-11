-- A Trip can retain album-only photos without inventing a timestamp in its
-- factual route replay. Existing records were captured during a Trip, so they
-- remain timeline media.
alter table public.journey_media
  add column if not exists timeline_placed boolean not null default true;

comment on column public.journey_media.timeline_placed is
  'True when a photo belongs in the time-ordered Journey replay; false for album-only Trip media.';
