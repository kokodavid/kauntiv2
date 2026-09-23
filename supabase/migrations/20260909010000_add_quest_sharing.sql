-- MVP quest sharing: one revocable opaque code per quest, usable by link or code.
create table if not exists public.quest_share_tokens (
  quest_id uuid primary key references public.quests(id) on delete cascade,
  token_hash text not null unique,
  code text not null unique check (code ~ '^[A-Z0-9]{6}$'),
  created_by uuid not null references auth.users(id) on delete cascade,
  revoked_at timestamptz,
  created_at timestamptz not null default now()
);

alter table public.quest_share_tokens enable row level security;

create or replace function public.create_quest_share(p_quest_id uuid)
returns jsonb language plpgsql security definer set search_path = public, pg_temp as $$
declare v_code text; v_token text; v_hash text;
begin
  if auth.uid() is null then raise exception 'Authentication required'; end if;
  if not exists (select 1 from quests where id = p_quest_id and created_by = auth.uid()) then
    raise exception 'Only the quest owner can create a share';
  end if;
  -- Use primitives available on hosted Postgres without requiring pgcrypto.
  v_token := md5(random()::text || clock_timestamp()::text || auth.uid()::text)
    || md5(random()::text || clock_timestamp()::text);
  v_hash := md5(v_token);
  v_code := upper(substr(md5(random()::text || clock_timestamp()::text || p_quest_id::text), 1, 6));
  insert into quest_share_tokens(quest_id, token_hash, code, created_by)
  values (p_quest_id, v_hash, v_code, auth.uid())
  on conflict (quest_id) do update set token_hash = excluded.token_hash, code = excluded.code,
    created_by = excluded.created_by, revoked_at = null, created_at = now();
  return jsonb_build_object('quest_id', p_quest_id, 'code', v_code,
    'url', 'kaunti47://sidequest/join/' || v_code);
end; $$;

create or replace function public.resolve_quest_share(p_code text)
returns jsonb language sql security definer stable set search_path = public, pg_temp as $$
  select jsonb_build_object('quest_id', quest_id, 'code', code,
    'url', 'kaunti47://sidequest/join/' || code)
  from quest_share_tokens where code = upper(trim(p_code)) and revoked_at is null;
$$;

create or replace function public.join_quest_by_share(p_code text)
returns text language plpgsql security definer set search_path = public, pg_temp as $$
declare v_quest uuid;
begin
  if auth.uid() is null then raise exception 'Authentication required'; end if;
  select quest_id into v_quest from quest_share_tokens
    where code = upper(trim(p_code)) and revoked_at is null;
  if v_quest is null then raise exception 'Share code is invalid or revoked'; end if;
  return public.join_quest(v_quest);
end; $$;

revoke all on function public.create_quest_share(uuid) from public;
revoke all on function public.resolve_quest_share(text) from public;
revoke all on function public.join_quest_by_share(text) from public;
grant execute on function public.create_quest_share(uuid) to authenticated;
grant execute on function public.resolve_quest_share(text) to anon, authenticated;
grant execute on function public.join_quest_by_share(text) to authenticated;
