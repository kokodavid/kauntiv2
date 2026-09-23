-- Dev tool: seed a realistic mix of county_visits (badges) for one user,
-- so Map Home / Discover / the badge gallery can be reviewed against
-- something other than an empty board without waiting on real geofence
-- crossings (Module 4's Android-emulator geofencing is currently
-- unreliable -- see the implementation tracker).
--
-- Deliberately shipped as a `security definer` function restricted to
-- `service_role`, not a client-callable RPC: it writes rows for an
-- arbitrary user_id, which every RLS policy on county_visits/profiles/
-- county_depth_progress exists specifically to prevent from the app
-- side. Grant is service_role-only so it's only reachable from the
-- Supabase SQL Editor (which runs as an elevated role) or a script
-- holding the service role key -- never from the Flutter app's anon/
-- publishable key.
--
-- Usage (Supabase Dashboard -> SQL Editor):
--   select public.dev_seed_user_progress('someone@example.com');
--   select public.dev_seed_user_progress('a1b2c3d4-....-....-....-............');
-- Both a plain UUID string and an email address work as p_identifier --
-- the function tells them apart by whether the string parses as a UUID.
--
-- Idempotent by default (p_reset => true): re-running for the same user
-- clears this function's own prior seed for them first, so you can
-- re-seed after tweaking the county lists below without accumulating
-- duplicate rows. Pass p_reset => false to layer more rows on top of
-- whatever's already there instead.
create or replace function public.dev_seed_user_progress(
  p_identifier text,
  p_reset boolean default true,
  p_home_county_id smallint default 22 -- Kiambu, matching the current
                                        -- fake-geofencing test county
)
returns text
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid;
  v_explored smallint[] := array[
    47, -- Nairobi
    22, -- Kiambu
    16, -- Machakos
    21, -- Murang'a
    19, -- Nyeri
    32, -- Nakuru
    18, -- Nyandarua
    34, -- Kajiado
    1,  -- Mombasa
    2,  -- Kwale
    3,  -- Kilifi
    42, -- Kisumu
    27, -- Uasin Gishu
    29, -- Nandi
    35, -- Kericho
    33  -- Narok
  ];
  v_passed_through smallint[] := array[
    14, -- Embu
    12, -- Meru
    11, -- Isiolo
    31, -- Laikipia
    36, -- Bomet
    38  -- Vihiga
  ];
  v_code smallint;
  v_idx int;
  v_entered timestamptz;
begin
  -- Resolve the target user, accepting either a uid or an email so this
  -- can be called with whichever's easier to copy out of the Supabase
  -- Auth dashboard or the app's own logs.
  if p_identifier ~* '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$' then
    select id into v_user_id from auth.users where id = p_identifier::uuid;
  else
    select id into v_user_id from auth.users where lower(email) = lower(p_identifier);
  end if;

  if v_user_id is null then
    raise exception 'dev_seed_user_progress: no auth.users row for %', p_identifier;
  end if;

  if p_reset then
    delete from public.county_visits where user_id = v_user_id;
    delete from public.county_depth_progress where user_id = v_user_id;
  end if;

  -- Explored counties (badges earned): stagger entered_at/confirmed_at
  -- over the last several months so "latest unlock" ordering (Discover's
  -- MINE tab) and any recency-based UI has something real to sort by,
  -- rather than every badge sharing one timestamp.
  v_idx := 0;
  foreach v_code in array v_explored loop
    v_entered := now() - ((array_length(v_explored, 1) - v_idx) * interval '9 days')
                 - (v_idx * interval '3 hours');
    insert into public.county_visits
      (user_id, county_id, state, entered_at, confirmed_at, pass_count)
    values (
      v_user_id,
      v_code,
      'explored',
      v_entered,
      v_entered + interval '2 hours',
      1 + (v_idx % 3) -- a few return visits mixed in, not always 1
    )
    on conflict do nothing;
    v_idx := v_idx + 1;
  end loop;

  -- Passed-through counties: doc 07's personal-nudge query only surfaces
  -- these once pass_count >= 3, so seed them at 3 to make that quest
  -- type visible on Map Home / Side Quests immediately.
  v_idx := 0;
  foreach v_code in array v_passed_through loop
    v_entered := now() - ((array_length(v_passed_through, 1) - v_idx) * interval '5 days');
    insert into public.county_visits
      (user_id, county_id, state, entered_at, confirmed_at, pass_count)
    values (v_user_id, v_code, 'passed_through', v_entered, null, 3)
    on conflict do nothing;
    v_idx := v_idx + 1;
  end loop;

  -- A couple of depth-rank rows so doc 07's "held but not yet Local
  -- Expert" For-you candidate has something to surface too -- otherwise
  -- every explored county defaults to 'visitor' with no progress shown.
  insert into public.county_depth_progress (user_id, county_id, rank, updated_at)
  values
    (v_user_id, 47, 'regular', now()),   -- Nairobi: visited often, not maxed
    (v_user_id, 22, 'local_expert', now()) -- Kiambu (home county): maxed out
  on conflict (user_id, county_id) do update
    set rank = excluded.rank, updated_at = excluded.updated_at;

  -- Set a home county for this user if they don't already have a
  -- profile row, or have one with no home county chosen yet. Never
  -- overwrites a home county someone actually picked in onboarding.
  insert into public.profiles (id, home_county_id, location_mode)
  values (v_user_id, p_home_county_id, 'automatic')
  on conflict (id) do update
    set home_county_id = coalesce(public.profiles.home_county_id, excluded.home_county_id);

  return format(
    'Seeded %s explored + %s passed_through counties for user %s.',
    array_length(v_explored, 1),
    array_length(v_passed_through, 1),
    v_user_id
  );
end;
$$;

revoke execute on function public.dev_seed_user_progress(text, boolean, smallint) from public;
revoke execute on function public.dev_seed_user_progress(text, boolean, smallint) from authenticated;
grant execute on function public.dev_seed_user_progress(text, boolean, smallint) to service_role;
