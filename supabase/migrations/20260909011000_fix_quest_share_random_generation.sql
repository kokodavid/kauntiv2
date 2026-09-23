-- Replace pgcrypto-dependent generation for projects where gen_random_bytes is unavailable.
create or replace function public.create_quest_share(p_quest_id uuid)
returns jsonb language plpgsql security definer set search_path = public, pg_temp as $$
declare v_code text; v_token text; v_hash text;
begin
  if auth.uid() is null then raise exception 'Authentication required'; end if;
  if not exists (select 1 from quests where id = p_quest_id and created_by = auth.uid()) then
    raise exception 'Only the quest owner can create a share';
  end if;
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
