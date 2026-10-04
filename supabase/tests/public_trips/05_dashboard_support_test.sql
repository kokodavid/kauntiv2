begin;
select tests.seed();
select tests.enable();
create table tests.state(name text primary key, value jsonb);
grant all on tests.state to authenticated, service_role;
insert into public.admin_members values (tests.actor('other'),'moderator','active',null);
-- A county-scoped moderator is not a public trip moderator.
insert into public.admin_members values (tests.actor('outsider'),'moderator','active',array[1]::smallint[]);

set local role authenticated;
do $$
declare candidate jsonb;
begin
  perform tests.login('owner');
  candidate := public.prepare_public_trip('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',gen_random_uuid(),'Dashboard trip',
    '[]'::jsonb,array['f1111111-1111-4111-8111-111111111111']::uuid[]);
  insert into tests.state values ('candidate',candidate);
end $$;
reset role;

-- Stand in for the sanitization worker.
update public.public_trip_revision_photos set status = 'ready', sanitized_path = 'pub/1/photo.jpg', width = 1200, height = 800;

set local role authenticated;
do $$
declare c jsonb; pub uuid; rev integer; queue jsonb; photos jsonb; reports jsonb; live jsonb; hidden jsonb; events jsonb; report_id uuid;
begin
  select value into c from tests.state where name = 'candidate';
  pub := (c->>'id')::uuid; rev := (c->>'revision')::integer;
  perform tests.login('owner');
  perform public.submit_public_trip(pub,rev,c->>'content_hash','public-trips-v1');

  -- Role checks.
  perform tests.login('other');
  perform tests.assert(public.can_moderate_public_trips(),'moderator can moderate');
  perform tests.login('admin');
  perform tests.assert(public.can_moderate_public_trips(),'admin can moderate');
  perform tests.login('viewer');
  perform tests.assert(not public.can_moderate_public_trips(),'ordinary user cannot moderate');
  perform tests.login('outsider');
  perform tests.assert(not public.can_moderate_public_trips(),'county-scoped moderator cannot moderate trips');
  perform tests.login('viewer');
  perform tests.expect_error(format('select public.list_public_trip_review_photos_dashboard(%L,%s)',pub,rev),'42501');
  perform tests.expect_error('select public.list_public_trip_publications_dashboard()','42501');
  perform tests.expect_error('select public.list_public_trip_moderation_events_dashboard()','42501');

  -- Review queue shows who submitted and the sanitized photo, never a private path.
  perform tests.login('other');
  queue := public.list_public_trip_reviews_dashboard();
  perform tests.assert(jsonb_array_length(queue) = 1,'submission is in the queue');
  perform tests.assert(queue#>>'{0,moderation,owner_email}' = 'owner@example.invalid','reviewer sees the submitter');
  perform tests.assert(queue#>>'{0,moderation,owner_id}' = tests.actor('owner')::text,'reviewer gets the owner id for suspension');
  perform tests.assert((queue#>>'{0,moderation,open_reports}')::int = 0 and queue#>>'{0,moderation,author_suspended}' = 'false','queue context');
  perform tests.assert(queue#>>'{0,photos,0,path}' is null,'queue projection carries no storage path');
  photos := public.list_public_trip_review_photos_dashboard(pub,rev);
  perform tests.assert(jsonb_array_length(photos) = 1 and photos#>>'{0,path}' = 'pub/1/photo.jpg','reviewer gets the sanitized photo path');
  perform tests.assert(public.list_public_trip_review_photos_dashboard(pub,rev+99) = '[]'::jsonb,'unknown revision has no photos');

  perform public.review_public_trip(pub,rev,c->>'content_hash','approve');
  perform tests.assert(public.list_public_trip_reviews_dashboard() = '[]'::jsonb,'approved trip leaves the queue');
  live := public.list_public_trip_publications_dashboard('live');
  perform tests.assert(jsonb_array_length(live) = 1 and live#>>'{0,title}' = 'Dashboard trip'
    and live#>>'{0,owner_email}' = 'owner@example.invalid' and live#>>'{0,author_name}' = 'Test Owner','live list');
  perform tests.assert(public.list_public_trip_publications_dashboard('hidden') = '[]'::jsonb,'nothing hidden yet');

  -- Reports carry context but never the reporter.
  perform tests.login('viewer');
  report_id := public.report_public_trip(pub,'privacy','Shows a gate');
  perform tests.login('other');
  reports := public.list_public_trip_reports_dashboard();
  perform tests.assert(jsonb_array_length(reports) = 1 and reports#>>'{0,title}' = 'Dashboard trip'
    and reports#>>'{0,owner_id}' = tests.actor('owner')::text and reports#>>'{0,live}' = 'true','report context');
  perform tests.assert(not (reports->0 ? 'reporter_id'),'reporter identity not exposed');
  perform tests.assert((public.list_public_trip_publications_dashboard('live')#>>'{0,open_reports}')::int = 1,'live list counts open reports');

  -- Hide, then browse hidden.
  perform public.set_public_trip_hidden_dashboard(pub,true);
  perform tests.assert(public.list_public_trip_publications_dashboard('live') = '[]'::jsonb,'hidden trip leaves live list');
  hidden := public.list_public_trip_publications_dashboard('hidden');
  perform tests.assert(jsonb_array_length(hidden) = 1 and hidden#>>'{0,live}' = 'false' and hidden#>>'{0,hidden}' = 'true','hidden list');
  perform tests.expect_error('select public.list_public_trip_publications_dashboard(''everything'')','22023');

  -- Audit trail.
  events := public.list_public_trip_moderation_events_dashboard();
  perform tests.assert(events#>>'{0,action}' = 'hide' and events#>>'{0,actor_email}' = 'other@example.invalid','latest event first');
  perform tests.assert((select count(*) from jsonb_array_elements(events) e where e->>'action' = 'approve') = 1,'approval audited');
  perform tests.assert(jsonb_array_length(public.list_public_trip_moderation_events_dashboard(50,null,pub)) >= 2,'filter by publication');
  perform tests.assert(public.list_public_trip_moderation_events_dashboard(50,(events#>>'{0,id}')::bigint,pub)#>>'{0,action}' = 'approve','paging by id');
  perform tests.expect_error('select public.list_public_trip_moderation_events_dashboard(500)','22023');
end $$;
reset role;

do $$ begin
  if to_regclass('storage.objects') is not null then
    perform tests.assert(exists(select 1 from pg_policies where schemaname = 'storage' and tablename = 'objects'
      and policyname = 'Moderators read sanitized public trip photos'),'moderator photo policy exists');
  end if;
end $$;
rollback;
