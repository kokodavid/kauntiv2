-- Completed Journeys are private account data. Recording stays local until
-- an entitlement-checked upload path is added; clients cannot insert rows yet.

create table public.journeys (
  id uuid primary key,
  user_id uuid not null references auth.users (id) on delete cascade,
  title text not null check (length(title) between 1 and 120),
  started_at timestamptz not null,
  ended_at timestamptz not null,
  distance_m numeric(12, 2) not null check (distance_m >= 0),
  created_at timestamptz not null default now(),
  constraint journeys_time_order check (ended_at > started_at)
);

create index journeys_user_started_idx
  on public.journeys (user_id, started_at desc);

create table public.journey_points (
  journey_id uuid not null references public.journeys (id) on delete cascade,
  sequence_number integer not null check (sequence_number >= 0),
  segment_number integer not null check (segment_number >= 0),
  recorded_at timestamptz not null,
  latitude numeric(9, 6) not null check (latitude between -90 and 90),
  longitude numeric(9, 6) not null check (longitude between -180 and 180),
  accuracy_m numeric(8, 2) not null check (accuracy_m >= 0),
  primary key (journey_id, sequence_number)
);

alter table public.journeys enable row level security;
alter table public.journey_points enable row level security;

create policy "Users can read their own journeys"
  on public.journeys for select to authenticated
  using (user_id = (select auth.uid()));

create policy "Users can delete their own journeys"
  on public.journeys for delete to authenticated
  using (user_id = (select auth.uid()));

create policy "Users can read points for their own journeys"
  on public.journey_points for select to authenticated
  using (
    exists (
      select 1 from public.journeys journey
      where journey.id = journey_id
        and journey.user_id = (select auth.uid())
    )
  );

-- No client insert/update policies: the upload RPC in the recording slice
-- will validate the Pro entitlement, owner, route shape and session timing.
