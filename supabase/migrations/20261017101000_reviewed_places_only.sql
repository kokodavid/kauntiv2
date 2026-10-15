-- Only reviewed, non-archived places are visible to regular app users.
-- Dashboard members retain access to all places for editorial workflows.

drop policy if exists "Signed in users read live places, admins read all" on public.places;

create policy "Reviewed places visible to users, admins read all"
  on public.places
  for select
  to authenticated
  using (
    (
      status = 'reviewed'
      and archived_at is null
    )
    or public.current_admin_role() is not null
  );
