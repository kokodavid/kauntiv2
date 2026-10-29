-- Trip plan notifications and Mute plan (S10 gaps).
--
-- Two new push kinds ride the existing push system:
--   plan_invite  someone invited you to a plan, or joined yours. Sent at
--                once (outside quiet hours) and exempt from the daily and
--                weekly caps, like review results.
--   plan_update  someone changed a plan you are on. Batched: one a plan an
--                hour at most (D9), only after edits have settled for 5
--                minutes, never to the person who made the last change and
--                never to anyone who muted the plan.
-- A member who muted a plan gets no plan_update from it and no join news.

alter table public.push_events drop constraint if exists push_events_kind_check;
alter table public.push_events add constraint push_events_kind_check
  check (kind in ('announcement', 'photo_review', 'trip_review', 'weekend_plan',
    'plan_invite', 'plan_update', 'test'));
alter table public.push_kind_settings drop constraint if exists push_kind_settings_kind_check;
alter table public.push_kind_settings add constraint push_kind_settings_kind_check
  check (kind in ('announcement', 'photo_review', 'trip_review', 'weekend_plan',
    'plan_invite', 'plan_update'));
insert into public.push_kind_settings (kind)
values ('plan_invite'), ('plan_update')
on conflict (kind) do nothing;

-- The claim function, unchanged except that plan_invite is exempt from the
-- daily and weekly caps (copied from 20261029100000).
create or replace function public.claim_push_events(p_limit integer default 50)
returns table (
  event_id uuid, user_id uuid, kind text, delivery text, title text, body text,
  dest_kind text, dest_id text, tokens text[], email text, first_name text
)
language plpgsql
security definer
set search_path = public
as $$
declare
  r public.push_events;
  v_ids uuid[] := '{}';
  v_flag boolean;
  v_delivery boolean;
  v_today int;
  v_week int;
  v_exempt boolean;
  v_has_tokens boolean;
begin
  perform public.push_require_service();
  v_flag := coalesce((select enabled from public.app_feature_flags
                      where feature_key = 'push_broadcasts'), false);
  v_delivery := coalesce((select delivery_enabled from public.beta_tester_invite_settings limit 1), false);

  for r in
    select * from public.push_events e
    where e.attempts < 5 and e.send_after <= now()
      and (e.status = 'queued' or (e.status = 'sending' and e.claimed_at < now() - interval '10 minutes'))
    order by e.send_after
    limit greatest(1, least(p_limit, 100)) * 3
    for update skip locked
  loop
    exit when coalesce(array_length(v_ids, 1), 0) >= least(p_limit, 100);
    if r.kind = 'announcement' and not v_flag then continue; end if; -- stays queued
    if r.delivery = 'email' and not v_delivery then continue; end if;

    if r.kind <> 'test' and not coalesce(
         (select s.enabled from public.push_kind_settings s where s.kind = r.kind), true) then
      update public.push_events set status = 'skipped', status_reason = 'paused' where id = r.id;
      continue;
    end if;
    if r.kind <> 'test' and not coalesce(public.push_profile_switch(r.user_id, r.kind), true) then
      update public.push_events set status = 'skipped', status_reason = 'opted_out' where id = r.id;
      continue;
    end if;

    if r.kind <> 'test' and r.delivery = 'push' then
      v_exempt := r.kind in ('photo_review', 'trip_review', 'plan_invite');
      select count(*) filter (where (e.sent_at at time zone 'Africa/Nairobi')::date
                                    = (now() at time zone 'Africa/Nairobi')::date),
             count(*)
      into v_today, v_week
      from public.push_events e
      where e.user_id = r.user_id and e.delivery = 'push' and e.status = 'sent'
        and e.kind <> 'test' and e.sent_at > now() - interval '7 days';
      if (v_exempt and v_today >= 3) or (not v_exempt and (v_today >= 1 or v_week >= 3)) then
        update public.push_events set status = 'skipped', status_reason = 'cap' where id = r.id;
        continue;
      end if;
    end if;

    if r.delivery = 'push' then
      select exists (select 1 from public.push_devices d
                     where d.user_id = r.user_id and d.os_permission = 'granted') into v_has_tokens;
      if not v_has_tokens then
        update public.push_events set status = 'skipped', status_reason = 'no_device' where id = r.id;
        perform public.push_fallback_to_email(r.id);
        continue;
      end if;
    end if;

    update public.push_events
    set status = 'sending', claimed_at = now(), attempts = attempts + 1
    where id = r.id;
    v_ids := v_ids || r.id;
  end loop;

  return query
  select e.id, e.user_id, e.kind, e.delivery,
         e.payload ->> 'title', e.payload ->> 'body',
         e.payload ->> 'dest_kind', e.payload ->> 'dest_id',
         case when e.delivery = 'push' then
           array(select d.token from public.push_devices d
                 where d.user_id = e.user_id and d.os_permission = 'granted')
         else '{}'::text[] end,
         case when e.delivery = 'email' then u.email::text end,
         (select nullif(split_part(btrim(coalesce(w.display_name, '')), ' ', 1), '')
          from public.waitlist_signups w where w.user_id = e.user_id limit 1)
  from public.push_events e
  join auth.users u on u.id = e.user_id
  where e.id = any (v_ids);
end;
$$;

-- Invitations and joins ------------------------------------------------------

create function trip_plan_private.queue_member_push()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare v_title text; v_owner uuid; v_who text; v_owner_muted boolean;
begin
  begin
    select p.title, p.owner_id into v_title, v_owner from public.trip_plans p where p.id = new.plan_id;
    if v_title is null then return new; end if;

    if new.status = 'invited' and (tg_op = 'INSERT' or old.status is distinct from 'invited') then
      select qp.handle into v_who from public.quest_public_profiles qp where qp.user_id = new.invited_by;
      insert into public.push_events (user_id, kind, delivery, payload, dedupe_key, send_after)
      values (new.user_id, 'plan_invite', 'push',
        jsonb_build_object('title', 'Trip plan invitation',
          'body', coalesce(v_who, 'Someone') || ' invited you to ' || v_title || '.',
          'dest_kind', 'trips'),
        'plan_invite:' || new.plan_id || ':' || new.user_id || ':' || gen_random_uuid(),
        public.push_next_send_time(now()));
    elsif new.status = 'joined' and new.role <> 'owner' and new.user_id <> v_owner
      and (tg_op = 'INSERT' or old.status is distinct from 'joined') then
      select m.muted into v_owner_muted from public.trip_plan_members m
      where m.plan_id = new.plan_id and m.user_id = v_owner;
      if coalesce(v_owner_muted, false) then return new; end if;
      select qp.handle into v_who from public.quest_public_profiles qp where qp.user_id = new.user_id;
      insert into public.push_events (user_id, kind, delivery, payload, dedupe_key, send_after)
      values (v_owner, 'plan_invite', 'push',
        jsonb_build_object('title', v_title,
          'body', coalesce(v_who, 'Someone') || ' joined your plan.',
          'dest_kind', 'plan', 'dest_id', new.plan_id::text),
        'plan_join:' || new.plan_id || ':' || new.user_id || ':' || gen_random_uuid(),
        public.push_next_send_time(now()));
    end if;
  exception when others then
    -- A notification problem must never undo an invitation or a join.
    null;
  end;
  return new;
end $$;

revoke execute on function trip_plan_private.queue_member_push() from public;

create trigger trip_plan_members_push
  after insert or update of status on public.trip_plan_members
  for each row execute function trip_plan_private.queue_member_push();

-- Changes, batched ------------------------------------------------------------

create table public.trip_plan_push_state (
  plan_id uuid primary key references public.trip_plans (id) on delete cascade,
  notified_at timestamptz not null default now()
);
alter table public.trip_plan_push_state enable row level security;
-- No policies: only enqueue_plan_updates() uses it.

create function public.enqueue_plan_updates()
returns integer
language plpgsql
security definer
set search_path = public
as $$
declare v_count integer;
begin
  perform public.push_require_service();
  with due as (
    select p.id, p.title, p.updated_at, p.updated_by
    from public.trip_plans p
    left join public.trip_plan_push_state s on s.plan_id = p.id
    where p.updated_by is not null
      and p.updated_at > coalesce(s.notified_at, p.created_at)
      and p.updated_at < now() - interval '5 minutes'
  ), sent as (
    insert into public.push_events (user_id, kind, delivery, payload, dedupe_key, send_after)
    select m.user_id, 'plan_update', 'push',
      jsonb_build_object('title', d.title,
        'body', coalesce(qp.handle, 'Someone') || ' made changes to the plan.',
        'dest_kind', 'plan', 'dest_id', d.id::text),
      'plan_update:' || d.id || ':' || m.user_id || ':' || extract(epoch from d.updated_at)::bigint,
      public.push_next_send_time(now())
    from due d
    join public.trip_plan_members m
      on m.plan_id = d.id and m.status = 'joined' and not m.muted and m.user_id <> d.updated_by
    left join public.quest_public_profiles qp on qp.user_id = d.updated_by
    on conflict (dedupe_key) do nothing
    returning 1
  ), marked as (
    insert into public.trip_plan_push_state (plan_id, notified_at)
    select id, now() from due
    on conflict (plan_id) do update set notified_at = excluded.notified_at
    returning 1
  )
  select count(*) into v_count from sent;
  return coalesce(v_count, 0);
end $$;
revoke execute on function public.enqueue_plan_updates() from public, anon, authenticated;

do $$
begin
  if exists (select 1 from pg_extension where extname = 'pg_cron') then
    perform cron.schedule('plan-updates', '7 * * * *', 'select public.enqueue_plan_updates()');
  end if;
end $$;

-- Mute plan ---------------------------------------------------------------------

-- Whether I muted this plan (get_trip_plan does not say).
create function public.my_trip_plan_muted(p_plan uuid)
returns boolean
language plpgsql
stable
security definer
set search_path = ''
as $$
declare v_muted boolean;
begin
  perform trip_plan_private.assert_enabled();
  select m.muted into v_muted from public.trip_plan_members m
  where m.plan_id = p_plan and m.user_id = auth.uid() and m.status = 'joined';
  if not found then
    raise exception 'trip_plan_not_found' using errcode = 'P0002';
  end if;
  return v_muted;
end $$;
revoke execute on function public.my_trip_plan_muted(uuid) from public;
grant execute on function public.my_trip_plan_muted(uuid) to authenticated;
