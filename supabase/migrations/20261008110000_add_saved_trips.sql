-- Saved trip plans: a destination place and the stops planned on the way,
-- so a user does not rebuild the same trip every time. Only the plan is
-- kept, not the route: that starts from wherever the user is, so it is
-- worked out again when the plan is opened.
--
-- Stops are place ids in an array (a place that is later removed simply
-- drops out of the plan when it is opened). When custom_order is false the
-- ids are stored sorted and the app picks the driving order; when true they
-- are in the order the user chose.
create table public.saved_trips (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid()
    references auth.users (id) on delete cascade,
  name text not null
    check (length(btrim(name)) between 1 and 80),
  destination_place_id uuid not null
    references public.places (id) on delete cascade,
  stop_place_ids uuid[] not null default '{}'
    check (cardinality(stop_place_ids) <= 6),
  custom_order boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- The same plan cannot be saved twice by the same user.
create unique index saved_trips_unique_plan_idx
  on public.saved_trips (
    user_id, destination_place_id, stop_place_ids, custom_order
  );

create index saved_trips_user_destination_idx
  on public.saved_trips (user_id, destination_place_id);

alter table public.saved_trips enable row level security;

create policy "Users read their own saved trips"
  on public.saved_trips
  for select
  to authenticated
  using (user_id = auth.uid());

-- At most 50 saved trips each, so the list cannot grow without bound.
create policy "Users save their own trips"
  on public.saved_trips
  for insert
  to authenticated
  with check (
    user_id = auth.uid()
    and (
      select count(*) from public.saved_trips s where s.user_id = auth.uid()
    ) < 50
  );

create policy "Users rename their own saved trips"
  on public.saved_trips
  for update
  to authenticated
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

create policy "Users delete their own saved trips"
  on public.saved_trips
  for delete
  to authenticated
  using (user_id = auth.uid());

grant select, insert, update, delete on public.saved_trips to authenticated;
