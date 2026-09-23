create table if not exists public.quest_images (
  id uuid primary key default gen_random_uuid(),
  quest_id uuid not null references public.quests(id) on delete cascade,
  image_url text not null check (length(trim(image_url)) > 0),
  sort_order integer not null default 0 check (sort_order >= 0),
  created_at timestamptz not null default now(),
  unique (quest_id, sort_order)
);

alter table public.quest_images enable row level security;

create policy "Eligible users can read quest images"
  on public.quest_images for select to authenticated
  using (public.can_view_quest(quest_id));

create policy "Creators can manage quest images"
  on public.quest_images for all to authenticated
  using (exists (
    select 1 from public.quests q
    where q.id = quest_id and q.created_by = auth.uid()
  ))
  with check (exists (
    select 1 from public.quests q
    where q.id = quest_id and q.created_by = auth.uid()
  ));

insert into storage.buckets (id, name, public)
values ('quest-images', 'quest-images', true)
on conflict (id) do update set public = true;

create policy "Quest image uploads"
  on storage.objects for insert to authenticated
  with check (
    bucket_id = 'quest-images'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

create policy "Quest image updates"
  on storage.objects for update to authenticated
  using (
    bucket_id = 'quest-images'
    and owner_id = auth.uid()::text
  );

create policy "Quest image deletes"
  on storage.objects for delete to authenticated
  using (
    bucket_id = 'quest-images'
    and owner_id = auth.uid()::text
  );
