-- Open beta feedback to every signed-in user, not only founder-seat holders.
--
-- has_tester_seat() is the single gate for the Profile "Beta feedback" tile,
-- submit_feedback, add_feedback_attachment and the feedback-media storage
-- policy. Until now it required an approved waitlist seat, so testers who
-- were invited without a seat (most of the beta) could not send feedback.
--
-- Unchanged: anon is still revoked, submit_feedback keeps its cap of 20
-- reports per user per 24 h and its length checks.
--
-- Applied to prod by hand in the SQL editor on 2026-11-27. Previous body:
--   select exists (select 1 from public.waitlist_signups w
--     where w.status = 'approved'
--       and (w.user_id = auth.uid()
--            or w.email_key = lower(coalesce(auth.jwt() ->> 'email', ''))));
-- The name is kept so no caller changes; rename in a later cleanup.

create or replace function public.has_tester_seat()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select auth.uid() is not null;
$$;
