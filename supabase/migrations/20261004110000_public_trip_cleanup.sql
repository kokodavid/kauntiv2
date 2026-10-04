-- Schedule from trusted operations only. No client can purge review evidence.
create function public.cleanup_public_trips()
returns jsonb language plpgsql security definer set search_path = '' as $$
declare v_revisions integer; v_reports integer;
begin
  delete from public.public_trip_revisions r where
    (status = 'prepared' and expires_at <= now()) or
    (status in ('revoked','rejected','superseded')
      and greatest(prepared_at,coalesce(reviewed_at,prepared_at)) < now() - interval '24 hours');
  get diagnostics v_revisions = row_count;
  -- Open reports stay actionable; only resolved reports age out.
  delete from public.public_trip_reports where state = 'resolved' and resolved_at < now() - interval '90 days';
  get diagnostics v_reports = row_count;
  delete from public.public_trip_moderation_events where created_at < now() - interval '90 days';
  delete from public_trip_private.rate_limits where window_start < now() - interval '2 days';
  -- Request records contain no route data. Keep withdrawal tokens until source
  -- deletion to ensure a delayed retry never withdraws a later publication.
  return jsonb_build_object('revisions_deleted',v_revisions,'resolved_reports_deleted',v_reports);
end $$;
revoke all on function public.cleanup_public_trips() from public,anon,authenticated;
grant execute on function public.cleanup_public_trips() to service_role;
