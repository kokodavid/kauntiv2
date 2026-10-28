-- Usernames: server-owned, friendly, never derived from personal data.
--
-- * New accounts get a generated handle shaped `word` + short number
--   (nyati7, chui42). Words come from an editable table.
-- * Users choose their own through suggest/check/set RPCs: reserved and
--   blocked words, case-insensitive uniqueness (handles are lowercase), a
--   30 day change limit and a 30 day hold on a released handle.
-- * `username_is_generated` replaces the old "does it look like user-<hex>"
--   guess behind has_chosen_username(). Existing accounts keep their handle.
--
-- Clients can still write `handle` directly until supabase/deferred/
-- username_lockdown.sql is applied (do that once most people are on the app
-- build with the username screens); after it, the RPCs below are the only
-- way, so the rules cannot be bypassed.

-- ---------------------------------------------------------------- tables

create table if not exists public.username_words (
  word text primary key check (word ~ '^[a-z]{3,12}$'),
  active boolean not null default true
);

create table if not exists public.username_reserved (
  handle text primary key check (handle = lower(handle))
);

create table if not exists public.username_blocked_terms (
  term text primary key check (term = lower(term) and char_length(term) >= 3)
);

create table if not exists public.username_history (
  id bigint generated always as identity primary key,
  user_id uuid not null references auth.users (id) on delete cascade,
  old_handle text not null,
  released_at timestamptz not null,
  -- True when staff reset the name: even its old owner can't take it back
  -- until released_at.
  blocked_for_owner boolean not null default false
);

create index if not exists username_history_handle_idx
  on public.username_history (old_handle, released_at);

alter table public.username_words enable row level security;
alter table public.username_reserved enable row level security;
alter table public.username_blocked_terms enable row level security;
alter table public.username_history enable row level security;
-- No policies on purpose: only security definer functions touch these.

alter table public.quest_public_profiles
  add column if not exists username_is_generated boolean not null default true,
  add column if not exists username_changed_at timestamptz;

-- Existing accounts keep what they have. Only the old untouched default
-- (`user-` + 8 hex) counts as "not chosen yet".
update public.quest_public_profiles
set username_is_generated = (handle ~ '^user-[0-9a-f]{8}$');

-- ------------------------------------------------------------------ seeds

insert into public.username_words (word) values
  ('nyati'),('chui'),('twiga'),('simba'),('tembo'),('kifaru'),('fisi'),
  ('kiboko'),('tausi'),('korongo'),('swala'),('pofu'),('duma'),
  ('nyumbu'),('mbuni'),('kongoni'),('digidigi'),('ngiri'),('kunguru'),
  ('tai'),('kipepeo'),('nyuki'),('samaki'),('kasuku'),('mamba'),
  ('baobab'),('mwitu'),('savanna'),('mara'),('tsavo'),('rift'),('safari'),
  ('bonde'),('mlima'),('ziwa'),('mto'),('pwani'),('bahari'),('kisiwa'),
  ('jangwa'),('msitu'),('pori'),('bonde'),('maporomoko'),('chemchem'),
  ('jua'),('nyota'),('mwezi'),('alfajiri'),('machweo'),('upepo'),('mvua'),
  ('radi'),('moto'),('mawe'),('mchanga'),('majani'),('maua'),('mti'),
  ('mbuyu'),('mkoko'),('mikoko'),('kilele'),('njia'),('safiri'),('tembea'),
  ('gundua'),('panda'),('kimbia'),('rafiki'),('shujaa'),('jasiri'),
  ('msafiri'),('mgunduzi'),('kambi'),('moto'),
  ('dira'),('ramani'),('safari'),('nyika'),('tambarare'),('mwamba'),
  ('pango'),('lava'),('mawimbi'),('tumbawe'),
  ('matumbawe'),('pomboo'),('kasa'),('nungu'),
  ('sungura'),('paka'),('mbweha'),('ndovu'),('kulungu'),('tumbili'),
  ('nyani'),('ngedere'),('popo'),('bundi'),('mwewe'),('flamingo'),
  ('pelikani'),('kingfisher'),('weaver'),('sunbird'),('hornbill')
on conflict (word) do nothing;

insert into public.username_reserved (handle) values
  ('admin'),('administrator'),('kaunti47'),('kaunti'),('kaunti-47'),
  ('support'),('help'),('moderator'),('mod'),('staff'),('team'),
  ('official'),('root'),('system'),('null'),('undefined'),('api'),('www'),
  ('anonymous'),('security'),('billing'),('ads'),('owner'),('editor'),
  ('kenya'),('settings'),('profile'),('feedback'),('privacy'),('terms')
on conflict (handle) do nothing;

-- A deliberately short starter list (English and Swahili). Matching is a
-- substring match on the handle with `-` and `_` removed. Extend it from
-- the dashboard or SQL; keep it to terms that are unambiguous.
insert into public.username_blocked_terms (term) values
  ('fuck'),('shit'),('bitch'),('cunt'),('dick'),('pussy'),('nigg'),
  ('rape'),('nazi'),('whore'),('slut'),('malaya'),('kuma'),('mavi'),
  ('hitler'),('isis')
on conflict (term) do nothing;

-- ------------------------------------------------------------- internals

-- Why a handle can't be used, or null if it can. `p_user` is the caller so
-- their own current handle and their own held handles don't count as taken.
create or replace function public.username_problem(p_handle text, p_user uuid)
returns text
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
declare
  v_flat text;
begin
  if p_handle is null
     or p_handle !~ '^[a-z0-9][a-z0-9_-]{2,29}$'
     or p_handle !~ '[a-z]' then
    return 'invalid';
  end if;

  if exists (select 1 from public.username_reserved r where r.handle = p_handle) then
    return 'reserved';
  end if;

  v_flat := replace(replace(p_handle, '-', ''), '_', '');
  if exists (
    select 1 from public.username_blocked_terms t
    where position(t.term in v_flat) > 0
  ) then
    return 'blocked';
  end if;

  if exists (
    select 1 from public.quest_public_profiles p
    where p.handle = p_handle and p.user_id is distinct from p_user
  ) or exists (
    select 1 from public.username_history h
    where h.old_handle = p_handle
      and h.released_at > now()
      and (h.user_id is distinct from p_user or h.blocked_for_owner)
  ) then
    return 'taken';
  end if;

  return null;
end;
$$;

-- One random free handle: a random active word plus the shortest number
-- range that still has a free name. Never uses personal data.
create or replace function public.generate_username(
  p_exclude_words text[] default '{}'
)
returns text
language plpgsql
volatile
security definer
set search_path = public, pg_temp
as $$
declare
  v_ranges int[][] := array[[1, 99], [100, 999], [1000, 9999], [10000, 99999]];
  v_tier int;
  v_try int;
  v_word text;
  v_candidate text;
begin
  for v_tier in 1 .. 4 loop
    for v_try in 1 .. 12 loop
      select w.word into v_word
      from public.username_words w
      where w.active and w.word <> all (p_exclude_words)
      order by random()
      limit 1;

      if v_word is null then
        select w.word into v_word
        from public.username_words w
        where w.active
        order by random()
        limit 1;
      end if;

      if v_word is null then
        exit;
      end if;

      v_candidate := v_word || (
        v_ranges[v_tier][1]
        + floor(random() * (v_ranges[v_tier][2] - v_ranges[v_tier][1] + 1))::int
      )::text;

      if public.username_problem(v_candidate, null) is null then
        return v_candidate;
      end if;
    end loop;
  end loop;

  -- The word table is empty or exhausted: fall back to a neutral handle.
  return 'explorer' || floor(random() * 90000000 + 10000000)::bigint::text;
end;
$$;

-- ------------------------------------------------------- new-account paths

create or replace function public.create_quest_public_profile_for_new_user()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  insert into public.quest_public_profiles
    (user_id, display_name, handle, avatar_url, username_is_generated)
  values (
    new.id,
    left(coalesce(new.raw_user_meta_data ->> 'full_name',
                  new.raw_user_meta_data ->> 'name',
                  split_part(coalesce(new.email, 'Traveler'), '@', 1),
                  'Traveler'), 80),
    public.generate_username(),
    coalesce(new.raw_user_meta_data ->> 'avatar_url',
             new.raw_user_meta_data ->> 'picture'),
    true
  ) on conflict (user_id) do nothing;
  return new;
end;
$$;

create or replace function public.ensure_quest_public_profile()
returns public.quest_public_profiles
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_profile public.quest_public_profiles;
begin
  if auth.uid() is null then raise exception 'Authentication required'; end if;

  select * into v_profile from public.quest_public_profiles where user_id = auth.uid();
  if found then return v_profile; end if;

  insert into public.quest_public_profiles
    (user_id, display_name, handle, avatar_url, username_is_generated)
  values (
    auth.uid(),
    left(coalesce(auth.jwt() -> 'user_metadata' ->> 'full_name',
                  auth.jwt() -> 'user_metadata' ->> 'name',
                  split_part(coalesce(auth.jwt() ->> 'email', 'Traveler'), '@', 1),
                  'Traveler'), 80),
    public.generate_username(),
    coalesce(auth.jwt() -> 'user_metadata' ->> 'avatar_url',
             auth.jwt() -> 'user_metadata' ->> 'picture'),
    true
  )
  returning * into v_profile;
  return v_profile;
end;
$$;

-- --------------------------------------------------------- client-facing

create or replace function public.suggest_usernames(p_count integer default 4)
returns text[]
language plpgsql
volatile
security definer
set search_path = public, pg_temp
as $$
declare
  v_out text[] := '{}';
  v_words text[] := '{}';
  v_handle text;
  v_n int := least(greatest(coalesce(p_count, 4), 1), 8);
  v_i int := 0;
begin
  if auth.uid() is null then
    raise exception 'Authentication required' using errcode = '42501';
  end if;

  while coalesce(array_length(v_out, 1), 0) < v_n and v_i < v_n * 4 loop
    v_i := v_i + 1;
    v_handle := public.generate_username(v_words);
    if v_handle <> all (v_out) then
      v_out := v_out || v_handle;
      v_words := v_words || regexp_replace(v_handle, '[0-9]+$', '');
    end if;
  end loop;
  return v_out;
end;
$$;

-- 'available' | 'yours' | 'invalid' | 'reserved' | 'blocked' | 'taken'
create or replace function public.check_username(p_handle text)
returns text
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
declare
  v_handle text := lower(btrim(coalesce(p_handle, '')));
  v_problem text;
begin
  if auth.uid() is null then
    raise exception 'Authentication required' using errcode = '42501';
  end if;

  if exists (
    select 1 from public.quest_public_profiles p
    where p.user_id = auth.uid() and p.handle = v_handle
  ) then
    return 'yours';
  end if;

  v_problem := public.username_problem(v_handle, auth.uid());
  return coalesce(v_problem, 'available');
end;
$$;

create or replace function public.set_username(p_handle text)
returns table (handle text, username_is_generated boolean, username_changed_at timestamptz)
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_user uuid := auth.uid();
  v_handle text := lower(btrim(coalesce(p_handle, '')));
  v_profile public.quest_public_profiles;
  v_problem text;
begin
  if v_user is null then
    raise exception 'Authentication required' using errcode = '42501';
  end if;

  select * into v_profile
  from public.quest_public_profiles p
  where p.user_id = v_user
  for update;

  if not found then
    raise exception 'Profile not found' using errcode = 'P0002';
  end if;

  -- Same name: "Keep this one" just confirms a generated handle.
  if v_profile.handle = v_handle then
    update public.quest_public_profiles p
    set username_is_generated = false
    where p.user_id = v_user
    returning p.handle, p.username_is_generated, p.username_changed_at
    into handle, username_is_generated, username_changed_at;
    return next;
    return;
  end if;

  v_problem := public.username_problem(v_handle, v_user);
  if v_problem is not null then
    raise exception 'username_%', v_problem using errcode = '22023';
  end if;

  -- The first choice is free; later changes wait 30 days.
  if not v_profile.username_is_generated
     and v_profile.username_changed_at is not null
     and v_profile.username_changed_at > now() - interval '30 days' then
    raise exception 'username_rate_limited:%',
      to_char(v_profile.username_changed_at + interval '30 days', 'YYYY-MM-DD"T"HH24:MI:SSOF')
      using errcode = '54000';
  end if;

  if not v_profile.username_is_generated then
    insert into public.username_history (user_id, old_handle, released_at)
    values (v_user, v_profile.handle, now() + interval '30 days');
  end if;

  begin
    update public.quest_public_profiles p
    set handle = v_handle,
        username_is_generated = false,
        username_changed_at = case
          when v_profile.username_is_generated then p.username_changed_at
          else now()
        end,
        updated_at = now()
    where p.user_id = v_user
    returning p.handle, p.username_is_generated, p.username_changed_at
    into handle, username_is_generated, username_changed_at;
  exception
    when unique_violation then
      raise exception 'username_taken' using errcode = '22023';
  end;

  return next;
end;
$$;

-- Redefined: the flag is the truth now, not a guess from the handle's shape.
create or replace function public.has_chosen_username(p_user_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.quest_public_profiles p
    where p.user_id = p_user_id
      and not p.username_is_generated
  );
$$;

-- ------------------------------------------------------------- privileges

revoke all on function public.username_problem(text, uuid) from public, anon, authenticated;
revoke all on function public.generate_username(text[]) from public, anon, authenticated;
revoke all on function public.suggest_usernames(integer) from public, anon;
revoke all on function public.check_username(text) from public, anon;
revoke all on function public.set_username(text) from public, anon;
grant execute on function public.suggest_usernames(integer) to authenticated;
grant execute on function public.check_username(text) to authenticated;
grant execute on function public.set_username(text) to authenticated;
revoke all on function public.has_chosen_username(uuid) from public, anon;
grant execute on function public.has_chosen_username(uuid) to authenticated;
