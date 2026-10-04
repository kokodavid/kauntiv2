begin;
select tests.seed();
select tests.enable();
create table tests.state(name text primary key, value jsonb);
grant all on tests.state to authenticated, service_role;

set local role authenticated;
do $$
declare candidate jsonb;
begin
  perform tests.login('owner');
  candidate := public.prepare_public_trip('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',gen_random_uuid(),'Viewer photos',
    '[]'::jsonb,array['f1111111-1111-4111-8111-111111111111']::uuid[]);
  insert into tests.state values ('candidate',candidate);
end $$;
reset role;

-- Stand in for the sanitization worker.
update public.public_trip_revision_photos set status = 'ready', sanitized_path = 'pub/1/photo.jpg', width = 1200, height = 800;

set local role authenticated;
do $$
declare c jsonb; pub uuid; rev integer; path text;
begin
  select value into c from tests.state where name = 'candidate';
  pub := (c->>'id')::uuid; rev := (c->>'revision')::integer;
  path := 'pub/1/photo.jpg';

  perform tests.login('owner');
  perform public.submit_public_trip(pub,rev,c->>'content_hash','public-trips-v1');

  -- Nothing is viewable before approval.
  perform tests.login('viewer');
  perform tests.assert(not public.can_view_public_trip_photo(path),'not viewable before approval');

  perform tests.login('admin');
  perform public.review_public_trip(pub,rev,c->>'content_hash','approve');

  perform tests.login('viewer');
  perform tests.assert(public.can_view_public_trip_photo(path),'viewer can see a live trip photo');
  perform tests.assert(not public.can_view_public_trip_photo('pub/1/other.jpg'),'unknown path is not viewable');
  perform tests.assert(not public.can_view_public_trip_photo(null),'null path is not viewable');

  -- Blocking the author removes access to their photos.
  perform public.block_public_trip_author((c#>>'{author,id}')::uuid,true);
  perform tests.assert(not public.can_view_public_trip_photo(path),'blocked author photos are hidden');
  perform public.block_public_trip_author((c#>>'{author,id}')::uuid,false);
  perform tests.assert(public.can_view_public_trip_photo(path),'unblocking restores access');

  -- Withdrawing stops new signed URLs at once.
  perform tests.login('owner');
  perform public.withdraw_public_trip(pub,gen_random_uuid());
  perform tests.login('viewer');
  perform tests.assert(not public.can_view_public_trip_photo(path),'withdrawn trip photos are hidden');
end $$;
reset role;

do $$
begin
  if to_regclass('storage.objects') is not null then
    perform tests.assert(exists(select 1 from pg_policies where schemaname = 'storage' and tablename = 'objects'
      and policyname = 'Viewers read live public trip photos'),'viewer photo policy exists');
  end if;
end $$;
rollback;
