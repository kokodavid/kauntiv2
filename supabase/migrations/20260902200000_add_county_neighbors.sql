-- Adds county-to-county adjacency, needed by Module 4's geofencing
-- rolling registration (doc 01: iOS caps region monitoring at 20 zones,
-- so the app keeps the user's current county plus its nearest
-- neighboring boundaries registered, and re-registers on each crossing
-- rather than trying to watch all 47 at once).
--
-- Computed once from the same geoBoundaries ADM1 polygons the counties
-- seed used: two counties are neighbors if their boundaries touch (a
-- small ~200m buffer absorbs simplification/precision noise between
-- adjacent polygons that don't share an exact edge). This is a
-- static geographic fact, so it's seeded here rather than computed at
-- query time.
alter table public.counties
  add column if not exists neighbor_codes smallint[] not null default '{}';

update public.counties set neighbor_codes = '{2,3}' where id = 1;
update public.counties set neighbor_codes = '{1,3,6}' where id = 2;
update public.counties set neighbor_codes = '{1,2,4,6}' where id = 3;
update public.counties set neighbor_codes = '{3,5,6,7,11,15}' where id = 4;
update public.counties set neighbor_codes = '{4,7}' where id = 5;
update public.counties set neighbor_codes = '{2,3,4,15,17,34}' where id = 6;
update public.counties set neighbor_codes = '{4,5,8,11}' where id = 7;
update public.counties set neighbor_codes = '{7,9,10,11}' where id = 8;
update public.counties set neighbor_codes = '{8}' where id = 9;
update public.counties set neighbor_codes = '{8,11,23,25}' where id = 10;
update public.counties set neighbor_codes = '{4,7,8,10,12,15,25,31}' where id = 11;
update public.counties set neighbor_codes = '{11,13,14,15,19,20,31}' where id = 12;
update public.counties set neighbor_codes = '{12,14,15,19,20}' where id = 13;
update public.counties set neighbor_codes = '{12,13,15,16,19,20,21}' where id = 14;
update public.counties set neighbor_codes = '{4,6,11,12,13,14,16,17}' where id = 15;
update public.counties set neighbor_codes = '{14,15,17,20,21,22,34,47}' where id = 16;
update public.counties set neighbor_codes = '{6,15,16,34}' where id = 17;
update public.counties set neighbor_codes = '{19,21,22,31,32}' where id = 18;
update public.counties set neighbor_codes = '{12,13,14,18,20,21,31}' where id = 19;
update public.counties set neighbor_codes = '{12,13,14,16,19,21}' where id = 20;
update public.counties set neighbor_codes = '{14,16,18,19,20,22}' where id = 21;
update public.counties set neighbor_codes = '{16,18,21,32,34,47}' where id = 22;
update public.counties set neighbor_codes = '{10,24,25,30}' where id = 23;
update public.counties set neighbor_codes = '{23,26,28,30}' where id = 24;
update public.counties set neighbor_codes = '{10,11,23,30,31}' where id = 25;
update public.counties set neighbor_codes = '{24,27,28,37,39}' where id = 26;
update public.counties set neighbor_codes = '{26,28,29,30,35,37}' where id = 27;
update public.counties set neighbor_codes = '{24,26,27,30}' where id = 28;
update public.counties set neighbor_codes = '{27,35,37,38,42}' where id = 29;
update public.counties set neighbor_codes = '{23,24,25,27,28,31,32,35}' where id = 30;
update public.counties set neighbor_codes = '{11,12,18,19,25,30,32}' where id = 31;
update public.counties set neighbor_codes = '{18,22,30,31,33,34,35,36}' where id = 32;
update public.counties set neighbor_codes = '{32,34,36,44,45,46}' where id = 33;
update public.counties set neighbor_codes = '{6,16,17,22,32,33,47}' where id = 34;
update public.counties set neighbor_codes = '{27,29,30,32,36,42,43,46}' where id = 35;
update public.counties set neighbor_codes = '{32,33,35,45,46}' where id = 36;
update public.counties set neighbor_codes = '{26,27,29,38,39,40,41}' where id = 37;
update public.counties set neighbor_codes = '{29,37,41,42}' where id = 38;
update public.counties set neighbor_codes = '{26,37,40}' where id = 39;
update public.counties set neighbor_codes = '{37,39,41}' where id = 40;
update public.counties set neighbor_codes = '{37,38,40,42,43}' where id = 41;
update public.counties set neighbor_codes = '{29,35,38,41,43}' where id = 42;
update public.counties set neighbor_codes = '{35,41,42,44,45,46}' where id = 43;
update public.counties set neighbor_codes = '{33,43,45}' where id = 44;
update public.counties set neighbor_codes = '{33,36,43,44,46}' where id = 45;
update public.counties set neighbor_codes = '{33,35,36,43,45}' where id = 46;
update public.counties set neighbor_codes = '{16,22,34}' where id = 47;
