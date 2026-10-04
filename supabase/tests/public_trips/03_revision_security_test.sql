begin;
select tests.seed();
select tests.enable();
create table tests.context(candidate jsonb);
grant all on tests.context to authenticated;
set local role authenticated;
do $$
declare first jsonb; second jsonb; pub uuid;
begin
  perform tests.login('owner');
  first := public.prepare_public_trip('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',gen_random_uuid(),'First');
  pub := (first->>'id')::uuid;
  perform public.submit_public_trip(pub,1,first->>'content_hash','public-trips-v1');
  second := public.prepare_public_trip('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',gen_random_uuid(),'Second');
  perform tests.login('admin');
  perform tests.expect_error(format('select public.review_public_trip(%L,1,%L,%L)',pub,first->>'content_hash','approve'),
    '22023','Only consented');
  perform tests.login('owner');
  perform public.submit_public_trip(pub,2,second->>'content_hash','public-trips-v1');
  perform tests.login('admin');
  perform public.review_public_trip(pub,2,second->>'content_hash','approve');
  perform tests.login('other');
  perform tests.expect_error(format('select public.withdraw_public_trip(%L,gen_random_uuid())',pub),'42501');
  perform tests.expect_error($q$select public.prepare_public_trip('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
    gen_random_uuid(),'Stolen')$q$,'42501');
  perform tests.assert(public.my_public_trip('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa') is null,'owner status scoped');
  insert into tests.context values(second);
end $$;
reset role;

-- A change to private points revokes all public copies in the same transaction.
update public.journey_points set latitude = latitude+0.000001 where sequence_number = 30;
set local role authenticated;
do $$
declare candidate jsonb := (select c.candidate from tests.context c); pub uuid;
begin
  pub := (candidate->>'id')::uuid;
  perform tests.login('viewer');
  perform tests.assert(public.get_public_trip(pub) is null,'source edit revokes publication');
  perform tests.login('admin');
  perform tests.expect_error(format('select public.review_public_trip(%L,2,%L,%L)',pub,candidate->>'content_hash','approve'),'22023');
  perform public.set_public_trip_hidden_dashboard(pub,true);
  perform tests.login('owner');
  perform tests.expect_error($q$select public.prepare_public_trip('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
    gen_random_uuid(),'Hidden bypass')$q$,'42501');
  perform tests.login('admin');
  perform public.set_public_trip_hidden_dashboard(pub,false);
  perform tests.login('viewer');
  perform tests.assert(public.get_public_trip(pub) is null,'unhide does not automatically republish');
end $$;
reset role;

-- Expired prepared candidates cannot be submitted; cleanup removes their geometry.
select tests.login('owner');
insert into tests.context select public.prepare_public_trip('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
  gen_random_uuid(),'Expired');
update public.public_trip_revisions set expires_at = now()-interval '1 second' where status = 'prepared';
set local role authenticated;
do $$
declare candidate jsonb := (select c.candidate from tests.context c order by (c.candidate->>'revision')::int desc limit 1);
begin
  perform tests.expect_error(format('select public.submit_public_trip(%L,%s,%L,%L)',candidate->>'id',candidate->>'revision',
    candidate->>'content_hash','public-trips-v1'),'22023','expired');
end $$;
reset role;
select public.cleanup_public_trips();
select tests.assert(not exists(select 1 from public.public_trip_revisions where status = 'prepared'),'expired geometry deleted');

-- Source deletion cascades to publication, revisions, consents and request tokens.
set local role authenticated;
select tests.login('owner');
delete from public.journeys where id = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa';
reset role;
select tests.assert(not exists(select 1 from public.public_trip_publications),'source deletion removes public copy');
select tests.assert(not exists(select 1 from public.public_trip_revisions),'source deletion removes geometry');
select tests.assert(not exists(select 1 from public.public_trip_consents),'source deletion removes consents');
select tests.assert(not exists(select 1 from public_trip_private.requests),'source deletion removes request tokens');
rollback;
