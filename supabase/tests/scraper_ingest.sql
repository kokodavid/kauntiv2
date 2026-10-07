-- Run against a local database after all migrations. Rolls back all test data.
begin;

insert into auth.users (id, email) values
  ('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', 'scraper-editor@example.invalid');
insert into public.admin_members (user_id, role, status)
values ('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', 'editor', 'active');

insert into public.scrape_sources (slug, name, kind, enabled, licence_policy)
values ('wikidata-test', 'Wikidata', 'wikidata', false, 'CC0');

-- A public place the scraper must not duplicate.
insert into public.places (county_id, name, type, summary, location, source)
values (47, 'Nairobi National Park', 'National park', 'Existing.',
  st_setsrid(st_makepoint(36.85, -1.37), 4326), 'dashboard');

do $$
declare
  v_start jsonb;
  v_run uuid;
  v_out jsonb;
  v_candidate public.place_candidates;
  v_item jsonb := jsonb_build_object(
    'key', 'Q1', 'name', 'Karura Forest', 'type', 'Forest',
    'summary', 'Urban forest.', 'lat', -1.2386, 'lng', 36.8352,
    'source', 'Wikidata', 'source_url', 'https://www.wikidata.org/wiki/Q1',
    'licence', 'CC0',
    'images', jsonb_build_array(
      jsonb_build_object('key', 'img1', 'remote_url', 'https://commons.example/a.jpg',
        'licence', 'CC BY-SA 4.0', 'attribution', 'A. Photographer'),
      jsonb_build_object('key', 'img2', 'remote_url', 'https://commons.example/b.jpg')
    )
  );
begin
  -- The service role can run the lifecycle RPCs.
  insert into public.scrape_sources (slug, name, kind) values ('role-check', 'Role', 'openstreetmap');
  set local role service_role;
  perform public.start_scrape_run('role-check', 'manual', true);
  reset role;

  -- Scheduled runs are refused while the source is disabled; manual is fine.
  begin
    perform public.start_scrape_run('wikidata-test', 'schedule', false);
    raise exception 'scheduled run on a disabled source was allowed';
  exception when sqlstate '55000' then null;
  end;

  v_start := public.start_scrape_run('wikidata-test', 'manual', false);
  v_run := (v_start ->> 'run_id')::uuid;

  -- Only one live run per source.
  begin
    perform public.start_scrape_run('wikidata-test', 'manual', false);
    raise exception 'overlapping run was allowed';
  exception when sqlstate '55P03' then null;
  end;

  -- 1. Create. The county comes from the polygon, and the image without a
  -- licence is dropped.
  v_out := public.ingest_scrape_items(v_run, jsonb_build_array(v_item));
  if v_out -> 0 ->> 'outcome' <> 'created' then
    raise exception 'expected created, got %', v_out;
  end if;
  select * into v_candidate from public.place_candidates where source_item_key = 'Q1';
  if v_candidate.county_id <> 47 or v_candidate.origin <> 'scraper'
     or v_candidate.source_place_id is not null then
    raise exception 'candidate identity wrong: %', v_candidate;
  end if;
  if (select count(*) from public.place_candidate_images where candidate_id = v_candidate.id) <> 1 then
    raise exception 'unlicensed image was kept';
  end if;
  if not ('image review' = any (v_candidate.publish_blockers)) then
    raise exception 'image review blocker missing: %', v_candidate.publish_blockers;
  end if;

  -- 2. Same content again: unchanged, no second row.
  v_out := public.ingest_scrape_items(v_run, jsonb_build_array(v_item));
  if v_out -> 0 ->> 'outcome' <> 'unchanged' then
    raise exception 'expected unchanged, got %', v_out;
  end if;

  -- 3. Changed content on an untouched candidate is refreshed in place.
  v_out := public.ingest_scrape_items(v_run,
    jsonb_build_array(jsonb_set(v_item, '{summary}', '"Updated summary."')));
  if v_out -> 0 ->> 'outcome' <> 'updated' then
    raise exception 'expected updated, got %', v_out;
  end if;

  -- 4. After a person edits it, scraper changes become revisions.
  update public.place_candidates
  set content_synced_at = content_synced_at - interval '1 minute' where id = v_candidate.id;
  update public.place_candidates set summary = 'Editor wording.' where id = v_candidate.id;
  v_out := public.ingest_scrape_items(v_run,
    jsonb_build_array(jsonb_set(v_item, '{summary}', '"Scraper v3."')));
  if v_out -> 0 ->> 'outcome' <> 'revision' then
    raise exception 'expected revision, got %', v_out;
  end if;
  if (select summary from public.place_candidates where id = v_candidate.id) <> 'Editor wording.' then
    raise exception 'editor work was overwritten';
  end if;
  v_out := public.ingest_scrape_items(v_run,
    jsonb_build_array(jsonb_set(v_item, '{summary}', '"Scraper v4."')));
  if (select count(*) from public.place_candidate_revisions
      where candidate_id = v_candidate.id and status = 'pending') <> 1 then
    raise exception 'older pending revision was not superseded';
  end if;

  -- 5. Rejections and duplicates.
  v_out := public.ingest_scrape_items(v_run, jsonb_build_array(
    jsonb_build_object('key', 'Q2', 'name', 'No coords', 'type', 'Forest'),
    jsonb_build_object('key', 'Q3', 'name', 'Atlantic', 'type', 'Beach', 'lat', 0, 'lng', 0),
    jsonb_build_object('key', 'Q4', 'name', 'Wrong county', 'type', 'Forest',
      'lat', -1.2386, 'lng', 36.8352, 'county_id', 1),
    jsonb_build_object('key', 'Q5', 'name', 'Nairobi National Park', 'type', 'National park',
      'lat', -1.37, 'lng', 36.85),
    jsonb_build_object('key', 'Q6', 'name', 'karura  forest!', 'type', 'Forest',
      'lat', -1.2390, 'lng', 36.8360)
  ));
  if (select array_agg(r ->> 'outcome' order by r ->> 'key') from jsonb_array_elements(v_out) r)
     <> array['rejected', 'rejected', 'rejected', 'duplicate', 'duplicate'] then
    raise exception 'unexpected outcomes: %', v_out;
  end if;
  if (v_out -> 2 ->> 'reason') <> 'county_mismatch' then
    raise exception 'expected county_mismatch, got %', v_out -> 2;
  end if;

  -- 6. Counters on the run, and nothing reached public.places.
  if (select created_count from public.scrape_runs where id = v_run) <> 1
     or (select rejected_count from public.scrape_runs where id = v_run) <> 3 then
    raise exception 'run counters wrong';
  end if;
  if (select count(*) from public.places) <> 1 then
    raise exception 'scraper wrote to public.places';
  end if;

  -- 7. Failed runs leave the checkpoint alone; a clean run advances it.
  perform public.finish_scrape_run(v_run, 'failed', '{"cursor": 9}'::jsonb, 'boom');
  if (select checkpoint from public.scrape_sources where slug = 'wikidata-test') <> '{}'::jsonb then
    raise exception 'failed run moved the checkpoint';
  end if;
  v_start := public.start_scrape_run('wikidata-test', 'manual', false);
  perform public.finish_scrape_run((v_start ->> 'run_id')::uuid, 'succeeded', '{"cursor": 5}'::jsonb);
  if (select checkpoint ->> 'cursor' from public.scrape_sources where slug = 'wikidata-test') <> '5' then
    raise exception 'successful run did not move the checkpoint';
  end if;

  -- 8. A dry run reports outcomes but writes nothing.
  v_start := public.start_scrape_run('wikidata-test', 'manual', true);
  v_out := public.ingest_scrape_items((v_start ->> 'run_id')::uuid, jsonb_build_array(
    jsonb_build_object('key', 'Q9', 'name', 'Dry Falls', 'type', 'Waterfall',
      'lat', -1.2921, 'lng', 36.8219)));
  if v_out -> 0 ->> 'outcome' <> 'created'
     or exists (select 1 from public.place_candidates where source_item_key = 'Q9') then
    raise exception 'dry run wrote a candidate';
  end if;
  perform public.finish_scrape_run((v_start ->> 'run_id')::uuid, 'succeeded', '{"cursor": 99}'::jsonb);
  if (select checkpoint ->> 'cursor' from public.scrape_sources where slug = 'wikidata-test') <> '5' then
    raise exception 'dry run moved the checkpoint';
  end if;

  -- 9. The browser-facing publish RPC refuses scraped candidates.
  perform set_config('request.jwt.claim.sub', 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', true);
  set local role authenticated;
  begin
    perform public.publish_place_candidate_dashboard(v_candidate.id, 'test');
    raise exception 'scraped candidate was published by the old RPC';
  exception when sqlstate '0A000' then null;
  end;
  begin
    perform public.ingest_scrape_items(v_run, '[]'::jsonb);
    raise exception 'authenticated role could call the ingest RPC';
  exception when insufficient_privilege then null;
  end;
  reset role;
end;
$$;

rollback;
