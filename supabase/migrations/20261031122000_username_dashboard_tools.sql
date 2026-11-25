-- Staff tools for usernames (dashboard): reset one to a generated name, and
-- edit the word, blocked-term and reserved lists. Resets are open to
-- moderators and up; the lists are owner and admin only.

-- Note: the role checks use coalesce on purpose. For someone who is not
-- staff, current_admin_role() is null, and `not (null in (...))` is null,
-- which would let the call through.

-- Gives the account a fresh generated username and holds the old one for 90
-- days, even against its previous owner. The user can then choose again
-- (no 30 day wait). Display name and avatar are not touched.
create or replace function public.reset_username_dashboard(p_user_id uuid)
returns table (handle text, username_is_generated boolean)
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_old text;
  v_new text;
begin
  if not coalesce(public.can_moderate_users(), false) then
    raise exception 'Resetting a username requires owner, admin, or moderator access'
      using errcode = '42501';
  end if;

  select p.handle into v_old
  from public.quest_public_profiles p
  where p.user_id = p_user_id
  for update;

  if not found then
    raise exception 'This user has no public profile'
      using errcode = 'P0002';
  end if;

  v_new := public.generate_username();

  insert into public.username_history
    (user_id, old_handle, released_at, blocked_for_owner)
  values (p_user_id, v_old, now() + interval '90 days', true);

  update public.quest_public_profiles p
  set handle = v_new,
      username_is_generated = true,
      username_changed_at = null,
      updated_at = now()
  where p.user_id = p_user_id;

  return query select v_new, true;
end;
$$;

-- All three lists in one call: { words: [{word, active}], blocked: [...],
-- reserved: [...] }.
create or replace function public.username_lists_dashboard()
returns jsonb
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
begin
  if coalesce(public.current_admin_role()::text, '') not in ('owner', 'admin') then
    raise exception 'Username lists require owner or admin access'
      using errcode = '42501';
  end if;

  return jsonb_build_object(
    'words', coalesce((
      select jsonb_agg(jsonb_build_object('word', w.word, 'active', w.active)
                       order by w.word)
      from public.username_words w), '[]'::jsonb),
    'blocked', coalesce((
      select jsonb_agg(t.term order by t.term)
      from public.username_blocked_terms t), '[]'::jsonb),
    'reserved', coalesce((
      select jsonb_agg(r.handle order by r.handle)
      from public.username_reserved r), '[]'::jsonb)
  );
end;
$$;

-- kind: 'words' | 'blocked' | 'reserved'. A word that already exists is
-- switched back on.
create or replace function public.add_username_term_dashboard(
  p_kind text,
  p_value text
)
returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v text := lower(btrim(coalesce(p_value, '')));
begin
  if coalesce(public.current_admin_role()::text, '') not in ('owner', 'admin') then
    raise exception 'Username lists require owner or admin access'
      using errcode = '42501';
  end if;

  case p_kind
    when 'words' then
      if v !~ '^[a-z]{3,12}$' then
        raise exception 'A word is 3 to 12 letters, a to z'
          using errcode = '22023';
      end if;
      insert into public.username_words (word, active) values (v, true)
      on conflict (word) do update set active = true;
    when 'blocked' then
      if v !~ '^[a-z0-9]{3,30}$' then
        raise exception 'A blocked term is 3 to 30 letters or numbers'
          using errcode = '22023';
      end if;
      insert into public.username_blocked_terms (term) values (v)
      on conflict (term) do nothing;
    when 'reserved' then
      if v !~ '^[a-z0-9][a-z0-9_-]{1,29}$' then
        raise exception 'A reserved name is 2 to 30 letters, numbers, - or _'
          using errcode = '22023';
      end if;
      insert into public.username_reserved (handle) values (v)
      on conflict (handle) do nothing;
    else
      raise exception 'Unknown list' using errcode = '22023';
  end case;
end;
$$;

-- Words are switched off (so history is kept and no taken name changes);
-- blocked and reserved entries are deleted.
create or replace function public.remove_username_term_dashboard(
  p_kind text,
  p_value text
)
returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v text := lower(btrim(coalesce(p_value, '')));
begin
  if coalesce(public.current_admin_role()::text, '') not in ('owner', 'admin') then
    raise exception 'Username lists require owner or admin access'
      using errcode = '42501';
  end if;

  case p_kind
    when 'words' then
      update public.username_words set active = false where word = v;
    when 'blocked' then
      delete from public.username_blocked_terms where term = v;
    when 'reserved' then
      delete from public.username_reserved where handle = v;
    else
      raise exception 'Unknown list' using errcode = '22023';
  end case;
end;
$$;

revoke all on function public.reset_username_dashboard(uuid) from public, anon;
revoke all on function public.username_lists_dashboard() from public, anon;
revoke all on function public.add_username_term_dashboard(text, text) from public, anon;
revoke all on function public.remove_username_term_dashboard(text, text) from public, anon;
grant execute on function public.reset_username_dashboard(uuid) to authenticated;
grant execute on function public.username_lists_dashboard() to authenticated;
grant execute on function public.add_username_term_dashboard(text, text) to authenticated;
grant execute on function public.remove_username_term_dashboard(text, text) to authenticated;
