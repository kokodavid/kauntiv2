select set_config('test.role','owner',false);
do $$
declare s jsonb; first_row jsonb;
begin
 s:=public.dashboard_growth_stats(now()-interval '7 days',now(),false);
 first_row:=s->'leaderboard'->0;
 if first_row->>'user_id'<>'00000000-0000-0000-0000-000000000002' then raise exception 'Explored tie-break failed'; end if;
 if (first_row->>'total')::int<>3 or (s->'leaderboard'->1->>'total')::int<>3 then raise exception 'Distinct coverage failed'; end if;
 if jsonb_array_length(s->'leaderboard')<>2 then raise exception 'Privacy/hidden filtering failed'; end if;
 if (s->'counties'->>'this_week')::int<>6 then raise exception 'Inclusive lower date boundary or seed filter failed'; end if;
 s:=public.dashboard_growth_stats(now()-interval '7 days',now(),true);
 if (s->'leaderboard'->0->>'total')::int<>2 then raise exception 'First-reached period failed'; end if;
 s:=public.dashboard_growth_stats(now()-interval '60 days',now(),false);
 if (s->'growth'->>'retention_7_returned')::int<>2 or (s->'growth'->>'retention_30_returned')::int<>1 then raise exception 'Mature-cohort retention failed'; end if;
 if (s->'growth'->>'retention_7_eligible')::int<>3 then raise exception 'Retention denominator failed'; end if;
 s:=public.dashboard_growth_stats(now()-interval '3 days',now()-interval '2 days',true);
 if (s->'counties'->>'this_week')::int<>1 then raise exception 'Exclusive upper date boundary failed'; end if;
 s:=public.dashboard_growth_stats(now()-interval '41 days',now()-interval '39 days',true);
 if (s->'leaderboard'->0->>'explored')::int<>0 then raise exception 'Later explored upgrade leaked into historical ranking'; end if;
 s:=public.dashboard_growth_stats(null,null,false);
 if (s->'period'->>'comparable')::boolean then raise exception 'All-time comparison enabled'; end if;
 s:=public.dashboard_growth_stats(now()-interval '200 days',now()-interval '100 days',false);
 if jsonb_array_length(s->'leaderboard')<>0 or (s->'new_users'->>'signed_up')::int<>0 then raise exception 'Empty range failed'; end if;
 begin perform public.dashboard_growth_stats(now(),now()-interval '1 day',false); raise exception 'Invalid range allowed'; exception when invalid_parameter_value then null; end;
 perform set_config('test.role','viewer',false);
 begin perform public.dashboard_growth_stats(); raise exception 'Viewer allowed'; exception when insufficient_privilege then null; end;
 perform set_config('test.role','',false);
 begin perform public.dashboard_growth_stats(); raise exception 'Anonymous allowed'; exception when insufficient_privilege then null; end;
 if has_function_privilege('anon','public.dashboard_growth_stats(timestamptz,timestamptz,boolean)','EXECUTE') then raise exception 'Anonymous privilege allowed'; end if;
end $$;

select set_config('test.role','owner',false);
insert into public.profiles(id,created_at) values ('00000000-0000-0000-0000-000000000006',now()-interval '4 days');
insert into auth.users values ('00000000-0000-0000-0000-000000000006','new@example.test',now()-interval '4 days');
insert into public.waitlist_signups values
 ('00000000-0000-0000-0000-000000000016',null,'new@example.test'),
 ('00000000-0000-0000-0000-000000000017','00000000-0000-0000-0000-000000000002','existing@example.test');
insert into public.beta_tester_invites values
 ('00000000-0000-0000-0000-000000000016',now()-interval '6 days'),
 ('00000000-0000-0000-0000-000000000016',now()-interval '2 days'),
 ('00000000-0000-0000-0000-000000000017',now()-interval '5 days');
insert into public.journeys values ('00000000-0000-0000-0000-000000000026','00000000-0000-0000-0000-000000000006',now()-interval '3 days',null,1000);
do $$
declare s jsonb;
begin
 s:=public.dashboard_growth_stats(now()-interval '7 days',now(),false);
 if (s->'growth'->>'invited')::int<>2 or (s->'growth'->>'registered')::int<>1 then raise exception 'Invitation deduplication or acquisition timing failed'; end if;
 if (s->'growth'->>'invite_activated')::int<>0 then raise exception 'Unfinished trip counted as activation'; end if;
 update public.journeys set ended_at=now()-interval '1 day' where id='00000000-0000-0000-0000-000000000026';
 s:=public.dashboard_growth_stats(now()-interval '7 days',now(),false);
 if (s->'growth'->>'invite_activated')::int<>1 then raise exception 'Finished trip activation failed'; end if;
end $$;
