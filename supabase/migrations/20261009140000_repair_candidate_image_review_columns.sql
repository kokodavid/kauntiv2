-- Compatibility repair for projects that received the candidate intake
-- migrations without the historical image-review migration. Later candidate
-- RPCs and the asset function require these private-review fields.

alter table public.place_candidate_images
  alter column source_image_id drop not null,
  add column if not exists scrape_image_key text,
  add column if not exists remote_url text,
  add column if not exists staging_path text,
  add column if not exists staged_at timestamptz,
  add column if not exists approved_at timestamptz,
  add column if not exists approved_by uuid references auth.users (id) on delete set null,
  add column if not exists review_status text not null default 'not_required'
    check (review_status in ('not_required', 'pending', 'approved', 'rejected', 'failed')),
  add column if not exists review_note text,
  add column if not exists reviewed_at timestamptz,
  add column if not exists reviewed_by uuid references auth.users (id) on delete set null,
  add column if not exists stage_failure_reason text,
  add column if not exists staged_content_type text,
  add column if not exists staged_bytes integer;

create unique index if not exists place_candidate_images_scrape_key_idx
  on public.place_candidate_images (candidate_id, scrape_image_key)
  where scrape_image_key is not null;

update public.place_candidate_images
set review_status = 'pending'
where staging_path is not null
  and review_status = 'not_required';
