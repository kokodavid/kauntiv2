-- The "water" interest covers lakes, rivers, waterfalls and hot springs, but
-- its short name said "waterfalls", so Explore showed lakes under a
-- "Waterfalls" heading. Only touch rows still on the old seeded value, so a
-- name an admin chose in the dashboard is kept.
update public.interests
set short_name = 'lakes and waterfalls'
where key = 'water' and short_name = 'waterfalls';
