-- Dev tool: seed enough competitive data to verify the Ranks backend before
-- building Flutter UI.
--
-- Service-role only, like dev_seed_user_progress(): this writes arbitrary
-- users' profiles, attestation rows, seasons, and visit events. It must never
-- be callable from the app's anon/publishable key.
--
-- Usage (Supabase Dashboard -> SQL Editor):
--   select public.dev_seed_ranks_verification(array[
--     'you@example.com',
--     'friend-one@example.com',
--     'friend-two@example.com'
--   ]);
--
-- The first user becomes the current "You" fixture: home county Kiambu,
-- eligible, with enough events to appear on Kenya and county boards. Additional
-- supplied users become eligible competitors. If fewer than three identifiers
-- are supplied, the function still seeds the users it can resolve.
--
-- After running it, verify with:
--   select * from public.active_leaderboard_season();
--   select * from public.kenya_season_leaderboard();
--   select * from public.county_season_leaderboard(32, 'visitors');
--   select * from public.county_season_leaderboard(22, 'locals');
create or replace function public.dev_seed_ranks_verification(
  p_identifiers text[],
  p_reset boolean default true
)
returns text
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_ids uuid[] := array[]::uuid[];
  v_identifier text;
  v_user_id uuid;
  v_season_id uuid;
  v_starts_at timestamptz := date_trunc('day', now()) - interval '14 days';
  v_ends_at timestamptz := date_trunc('day', now()) + interval '76 days';
  v_count int;
begin
  if p_identifiers is null or array_length(p_identifiers, 1) is null then
    raise exception 'dev_seed_ranks_verification: pass at least one auth user email or uuid';
  end if;

  foreach v_identifier in array p_identifiers loop
    if v_identifier ~* '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$' then
      select id into v_user_id from auth.users where id = v_identifier::uuid;
    else
      select id into v_user_id from auth.users where lower(email) = lower(v_identifier);
    end if;

    if v_user_id is not null then
      v_user_ids := array_append(v_user_ids, v_user_id);
    end if;
  end loop;

  v_count := array_length(v_user_ids, 1);
  if v_count is null or v_count = 0 then
    raise exception 'dev_seed_ranks_verification: none of the supplied identifiers resolved to auth.users rows';
  end if;

  if p_reset then
    update public.leaderboard_seasons
      set status = 'closed',
          closed_at = coalesce(closed_at, now())
      where status = 'active';
  end if;

  insert into public.leaderboard_seasons (
    season_number,
    starts_at,
    ends_at,
    status
  )
  values (
    9001,
    v_starts_at,
    v_ends_at,
    'active'
  )
  on conflict (season_number) do update
    set starts_at = excluded.starts_at,
        ends_at = excluded.ends_at,
        status = 'active',
        closed_at = null
  returning id into v_season_id;

  if p_reset then
    delete from public.season_honours where user_id = any(v_user_ids);
    delete from public.county_visit_events where user_id = any(v_user_ids);
    delete from public.county_visits where user_id = any(v_user_ids);
    delete from public.county_depth_progress where user_id = any(v_user_ids);
  end if;

  for v_count in 1..array_length(v_user_ids, 1) loop
    v_user_id := v_user_ids[v_count];

    insert into public.profiles (
      id,
      home_county_id,
      location_mode,
      show_on_leaderboards
    )
    values (
      v_user_id,
      case v_count
        when 1 then 22 -- Kiambu local board fixture.
        when 2 then 47 -- Nairobi, so Nakuru remains a visitor board.
        else 32        -- Nakuru local board contrast.
      end,
      'automatic',
      true
    )
    on conflict (id) do update
      set home_county_id = excluded.home_county_id,
          location_mode = 'automatic',
          show_on_leaderboards = true;

    insert into public.competitive_device_attestations (
      user_id,
      provider,
      status,
      verified_at,
      expires_at,
      updated_at
    )
    values (
      v_user_id,
      'play_integrity',
      'verified',
      now(),
      v_ends_at + interval '30 days',
      now()
    )
    on conflict (user_id) do update
      set provider = excluded.provider,
          status = excluded.status,
          verified_at = excluded.verified_at,
          expires_at = excluded.expires_at,
          updated_at = excluded.updated_at;
  end loop;

  -- User 1: "You" fixture. Strong county-board showing in Nakuru visitors,
  -- Kiambu locals, and several rare/scarce counties for Kenya score.
  if array_length(v_user_ids, 1) >= 1 then
    perform public.dev_insert_ranks_visit_events(
      v_user_ids[1],
      array[32, 32, 32, 32, 32, 22, 22, 11, 23, 30]::smallint[],
      v_starts_at
    );
  end if;

  -- User 2: beats User 1 on Nakuru visitors but has fewer rare counties.
  if array_length(v_user_ids, 1) >= 2 then
    perform public.dev_insert_ranks_visit_events(
      v_user_ids[2],
      array[32, 32, 32, 32, 32, 32, 47, 16]::smallint[],
      v_starts_at
    );
  end if;

  -- User 3: local to Nakuru, so the same county events should appear on the
  -- Locals board, not the Visitors board.
  if array_length(v_user_ids, 1) >= 3 then
    perform public.dev_insert_ranks_visit_events(
      v_user_ids[3],
      array[32, 32, 32, 32, 22, 1]::smallint[],
      v_starts_at
    );
  end if;

  -- Negative controls for the first user: these should not affect any board.
  insert into public.county_visit_events (
    user_id,
    county_id,
    outcome,
    source,
    entered_at,
    confirmed_at
  )
  values
    (v_user_ids[1], 14, 'passed_through', 'automatic', v_starts_at + interval '1 day', now()),
    (v_user_ids[1], 12, 'explored', 'manual', v_starts_at + interval '2 days', now());

  return format(
    'Seeded active dev season %s and competitive fixtures for %s user(s).',
    v_season_id,
    array_length(v_user_ids, 1)
  );
end;
$$;

create or replace function public.dev_insert_ranks_visit_events(
  p_user_id uuid,
  p_county_ids smallint[],
  p_starts_at timestamptz
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_county_id smallint;
  v_idx int := 0;
  v_entered_at timestamptz;
  v_visit_id uuid;
begin
  foreach v_county_id in array p_county_ids loop
    v_entered_at := p_starts_at
      + interval '1 day'
      + (v_idx * interval '19 hours');

    insert into public.county_visit_events (
      user_id,
      county_id,
      outcome,
      source,
      entered_at,
      confirmed_at
    )
    values (
      p_user_id,
      v_county_id,
      'explored',
      'automatic',
      v_entered_at,
      v_entered_at + interval '2 hours'
    );

    select id into v_visit_id
    from public.county_visits
    where user_id = p_user_id
      and county_id = v_county_id
    order by entered_at desc
    limit 1
    for update;

    if v_visit_id is null then
      insert into public.county_visits (
        user_id,
        county_id,
        state,
        entered_at,
        confirmed_at,
        pass_count
      )
      values (
        p_user_id,
        v_county_id,
        'explored',
        v_entered_at,
        v_entered_at + interval '2 hours',
        1
      );
    else
      update public.county_visits
        set state = 'explored',
            entered_at = v_entered_at,
            confirmed_at = v_entered_at + interval '2 hours',
            pass_count = pass_count + 1
        where id = v_visit_id;
    end if;

    v_idx := v_idx + 1;
    v_visit_id := null;
  end loop;
end;
$$;

revoke execute on function public.dev_seed_ranks_verification(text[], boolean) from public;
revoke execute on function public.dev_seed_ranks_verification(text[], boolean) from authenticated;
grant execute on function public.dev_seed_ranks_verification(text[], boolean) to service_role;

revoke execute on function public.dev_insert_ranks_visit_events(uuid, smallint[], timestamptz) from public;
revoke execute on function public.dev_insert_ranks_visit_events(uuid, smallint[], timestamptz) from authenticated;
grant execute on function public.dev_insert_ranks_visit_events(uuid, smallint[], timestamptz) to service_role;
