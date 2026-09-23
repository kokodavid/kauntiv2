-- Profile & Settings (doc 02, doc 05) needs several user-controllable
-- settings that `profiles` has never had a column for: doc 05's own
-- "User controls (Settings / Your data)" list -- map visibility,
-- leaderboard visibility, and the two notification toggles Settings.dc.html
-- and DataPrivacy.dc.html both show as real, tappable rows. None of this
-- existed before this migration; every default below matches what the
-- design mocks show for a brand-new user (map visibility FRIENDS, both
-- notification toggles ON, on the leaderboards by default).
alter table public.profiles
  add column if not exists map_visibility text not null default 'friends'
    check (map_visibility in ('private', 'friends', 'public')),
  add column if not exists show_on_leaderboards boolean not null default true,
  add column if not exists notify_badge_unlocks boolean not null default true,
  add column if not exists notify_county_nudges boolean not null default true,
  -- Doc 05: "Home county ... Rate-limited (proposed: once per season)".
  -- There is no seasons table yet (Leaderboards & Seasons, PR #10, is
  -- still Planned) so "once per season" can't be enforced against a real
  -- season boundary. This column is a placeholder proxy only: the
  -- application layer treats a change as allowed once every 90 days
  -- (doc 02's own season length, reused as the closest stand-in), not a
  -- real season-close event -- flagged in
  -- `SupabaseSettingsRepository` rather than presented as the confirmed
  -- policy doc 05 itself calls still-proposed.
  add column if not exists home_county_changed_at timestamptz;
