-- Per-Trip photo limits: 25 for free accounts, 50 for Pro. The numbers live
-- in a small table so they can change without an app release. The limit
-- only gates *new* photos: a Trip that already holds more keeps them.
create table public.journey_media_limits (
  tier text primary key check (tier in ('free', 'pro')),
  max_photos smallint not null check (max_photos > 0)
);

insert into public.journey_media_limits (tier, max_photos)
values ('free', 25), ('pro', 50);

alter table public.journey_media_limits enable row level security;
revoke all on public.journey_media_limits from public, anon;
grant select on public.journey_media_limits to authenticated;

create policy "Anyone signed in reads the photo limits"
  on public.journey_media_limits
  for select
  to authenticated
  using (true);

-- The signed-in user's limit, for showing "12 of 25" and the upgrade hint.
create function public.my_journey_media_limit()
returns jsonb
language sql
stable
security definer
set search_path = public
as $$
  select jsonb_build_object(
    'is_pro', public.has_pro_at(auth.uid(), now()),
    'max_photos', (
      select max_photos from public.journey_media_limits
      where tier = case
        when public.has_pro_at(auth.uid(), now()) then 'pro'
        else 'free'
      end
    ),
    'pro_max_photos', (
      select max_photos from public.journey_media_limits where tier = 'pro'
    )
  );
$$;

revoke execute on function public.my_journey_media_limit() from public;
grant execute on function public.my_journey_media_limit() to authenticated;

-- Enforced on insert so no client can go past it. Existing rows are never
-- touched; deleting a photo frees a slot.
create function public.enforce_journey_media_limit()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_limit smallint;
  v_count integer;
begin
  select max_photos into v_limit
  from public.journey_media_limits
  where tier = case
    when public.has_pro_at(new.user_id, now()) then 'pro'
    else 'free'
  end;

  select count(*) into v_count
  from public.journey_media
  where journey_id = new.journey_id;

  if v_count >= v_limit then
    raise exception 'journey_media_limit' using errcode = 'P0001',
      detail = 'This Trip already has the most photos your plan allows.';
  end if;
  return new;
end;
$$;

create trigger journey_media_limit_before_insert
  before insert on public.journey_media
  for each row execute function public.enforce_journey_media_limit();
