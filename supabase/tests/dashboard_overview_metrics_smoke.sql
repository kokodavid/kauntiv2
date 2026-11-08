-- Run only after installing the overview migration. All test changes roll back.
begin;
set local statement_timeout = '60s';
do $$
declare u uuid; s jsonb; b jsonb; fn regprocedure;
begin
  select user_id into u from public.admin_members where role='owner' and status='active' limit 1;
  if u is null then raise exception 'Active owner required for smoke test'; end if;
  perform set_config('request.jwt.claim.sub',u::text,true);
  create temp table dm_trips(untrusted text);
  create temp table dl_people(untrusted text);
  s:=public.dashboard_overview_metrics(now()-interval '30 days',now());
  b:=public.dashboard_leaderboard_analysis(now()-interval '30 days',now());
  if not(s ?& ARRAY['north_star','states','new_people','records','leaderboard_preview']) then raise exception 'Missing overview sections'; end if;
  if not(b ?& ARRAY['spread','shared','table','home_groups','leaders_vs_everyone']) then raise exception 'Missing analysis sections'; end if;
  if exists(select 1 from jsonb_array_elements(b->'table') r where (r->>'total')::int<=3 or (r->>'total')::int<>(r->>'explored')::int+(r->>'passed_through')::int) then raise exception 'Invalid leaderboard coverage'; end if;
  perform public.dashboard_overview_metrics(null,null);
  perform public.dashboard_leaderboard_analysis(now()-interval '90 days',now()-interval '60 days');
  perform public.dashboard_people_in_state('travelling');
  perform set_config('request.jwt.claim.sub','',true);
  begin perform public.dashboard_overview_metrics(); raise exception 'Unauthorized overview allowed'; exception when insufficient_privilege then null; end;
  begin perform public.dashboard_leaderboard_analysis(); raise exception 'Unauthorized leaderboard allowed'; exception when insufficient_privilege then null; end;
  begin perform public.dashboard_people_in_state('new'); raise exception 'Unauthorized people list allowed'; exception when insufficient_privilege then null; end;
  for fn in select oid::regprocedure from pg_proc where pronamespace='public'::regnamespace and proname like 'dashboard_metric_%' loop
    if has_function_privilege('authenticated',fn,'EXECUTE') then raise exception 'Helper exposed: %',fn; end if;
  end loop;
end $$;
rollback;
