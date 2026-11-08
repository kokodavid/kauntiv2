select set_config('test.role','editor',true);
do $$
declare rows jsonb := '[{"external_id":"club-1","name":"Example Place","county_id":47,"type":"park","lat":-1.2,"lng":36.8,"source":"research","last_verified_at":"2026-01-01","visit_duration_minutes":60}]';
 r record; v_count integer;
begin
 select * into r from public.import_places_csv_dashboard(rows);
 if r.outcome<>'created' then raise exception 'Expected new place'; end if;
 if not exists(select 1 from public.places where id=r.place_id and status='draft' and reviewed_at is null and external_id='club-1' and lat=-1.2 and lng=36.8 and visit_duration_minutes=60) then raise exception 'Incorrect draft contents'; end if;
 select * into r from public.import_places_csv_dashboard(rows);
 if r.outcome<>'skipped_existing' then raise exception 'Retry duplicated place'; end if;
 select * into r from public.import_places_csv_dashboard(jsonb_set(jsonb_set(rows,'{0,external_id}','"another-id"'),'{0,source}','"other-source"'));
 if r.outcome<>'skipped_existing' then raise exception 'Named duplicate not skipped'; end if;
 if (select count(*) from public.places)<>1 then raise exception 'Duplicates inserted'; end if;
 select count(*) into v_count from public.places;
 begin
   perform public.import_places_csv_dashboard('[{"external_id":"new","name":"New place","county_id":22,"type":"stay","lat":0,"lng":37,"source":"research"},{"external_id":"bad","name":"Bad","county_id":47,"type":"country_club","lat":0,"lng":37,"source":"research"}]');
   raise exception 'Bad batch accepted';
 exception when invalid_parameter_value then null; end;
 if (select count(*) from public.places)<>v_count then raise exception 'Partial batch committed'; end if;
 begin perform public.import_places_csv_dashboard(jsonb_set(rows,'{0,status}','"reviewed"')); raise exception 'Publishing field accepted'; exception when invalid_parameter_value then null; end;
 begin perform public.import_places_csv_dashboard(jsonb_set(rows,'{0,lat}','999')); raise exception 'Bad coordinates accepted'; exception when invalid_parameter_value then null; end;
 begin perform public.import_places_csv_dashboard(jsonb_set(rows,'{0,county_id}','1')); raise exception 'Unknown county accepted'; exception when invalid_parameter_value then null; end;
 begin perform public.import_places_csv_dashboard(jsonb_set(rows,'{0,source_url}','"javascript:alert(1)"')); raise exception 'Unsafe URL accepted'; exception when invalid_parameter_value then null; end;
 begin perform public.import_places_csv_dashboard(jsonb_set(rows,'{0,last_verified_at}','"2099-01-01"')); raise exception 'Future date accepted'; exception when invalid_parameter_value then null; end;
 begin perform public.import_places_csv_dashboard('[]'); raise exception 'Empty batch accepted'; exception when invalid_parameter_value then null; end;
 begin perform public.import_places_csv_dashboard((select jsonb_agg(rows->0) from generate_series(1,201))); raise exception 'Oversized batch accepted'; exception when invalid_parameter_value then null; end;
 -- Already-published and archived records are never overwritten or restored.
 update public.places set status='reviewed',summary='Keep me',archived_at=now();
 perform public.import_places_csv_dashboard(rows);
 if not exists(select 1 from public.places where status='reviewed' and summary='Keep me' and archived_at is not null) then raise exception 'Existing record changed'; end if;
 perform set_config('test.role','viewer',true);
 begin perform public.import_places_csv_dashboard(rows); raise exception 'Viewer allowed'; exception when insufficient_privilege then null; end;
 perform set_config('test.role','moderator',true);
 begin perform public.import_places_csv_dashboard(rows); raise exception 'Moderator allowed'; exception when insufficient_privilege then null; end;
 perform set_config('test.role','',true);
 begin perform public.import_places_csv_dashboard(rows); raise exception 'Unknown role allowed'; exception when insufficient_privilege then null; end;
 if has_function_privilege('anon','public.import_places_csv_dashboard(jsonb)','EXECUTE') then raise exception 'Anonymous execution allowed'; end if;
end $$;
