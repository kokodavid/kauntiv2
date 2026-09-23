-- Module 4's geofence circle radius per county, in meters.
--
-- Both Android's GeofencingClient and iOS's CLLocationManager region
-- monitoring only support circular regions, not arbitrary polygons -- so
-- a county's real (irregular) boundary can only be approximated by a
-- circle for the actual OS-level wake-up trigger. This radius is 0.8x
-- the radius of a circle with the same area as the county (biasing the
-- circle to sit mostly inside the county rather than spill far into
-- neighbors), computed from the same geoBoundaries polygons already
-- used elsewhere, clamped to [5km, 150km].
--
-- This is a deliberate MVP simplification: the circle alone decides
-- when to wake up and check, without a full point-in-polygon
-- confirmation against the real boundary once woken. Doc 01's
-- "hysteresis buffer" (don't count someone as entered right on the
-- boundary line) is approximated by the circle's own margin rather than
-- implemented as a separate precise check. Revisit by bundling real
-- polygon geometry into the app for on-device point-in-polygon
-- confirmation if this proves too imprecise in practice (e.g. two
-- adjacent large towns near a shared border).
alter table public.counties
  add column if not exists geofence_radius_m integer not null default 50000;

update public.counties set geofence_radius_m = 6815 where id = 1;
update public.counties set geofence_radius_m = 41115 where id = 2;
update public.counties set geofence_radius_m = 50630 where id = 3;
update public.counties set geofence_radius_m = 88079 where id = 4;
update public.counties set geofence_radius_m = 35575 where id = 5;
update public.counties set geofence_radius_m = 59309 where id = 6;
update public.counties set geofence_radius_m = 95883 where id = 7;
update public.counties set geofence_radius_m = 107848 where id = 8;
update public.counties set geofence_radius_m = 73043 where id = 9;
update public.counties set geofence_radius_m = 124789 where id = 10;
update public.counties set geofence_radius_m = 72106 where id = 11;
update public.counties set geofence_radius_m = 37618 where id = 12;
update public.counties set geofence_radius_m = 23403 where id = 13;
update public.counties set geofence_radius_m = 24078 where id = 14;
update public.counties set geofence_radius_m = 79167 where id = 15;
update public.counties set geofence_radius_m = 35719 where id = 16;
update public.counties set geofence_radius_m = 40472 where id = 17;
update public.counties set geofence_radius_m = 25911 where id = 18;
update public.counties set geofence_radius_m = 26149 where id = 19;
update public.counties set geofence_radius_m = 17406 where id = 20;
update public.counties set geofence_radius_m = 22829 where id = 21;
update public.counties set geofence_radius_m = 22975 where id = 22;
update public.counties set geofence_radius_m = 119608 where id = 23;
update public.counties set geofence_radius_m = 43226 where id = 24;
update public.counties set geofence_radius_m = 65752 where id = 25;
update public.counties set geofence_radius_m = 22579 where id = 26;
update public.counties set geofence_radius_m = 26199 where id = 27;
update public.counties set geofence_radius_m = 24879 where id = 28;
update public.counties set geofence_radius_m = 24262 where id = 29;
update public.counties set geofence_radius_m = 47056 where id = 30;
update public.counties set geofence_radius_m = 44566 where id = 31;
update public.counties set geofence_radius_m = 39078 where id = 32;
update public.counties set geofence_radius_m = 60580 where id = 33;
update public.counties set geofence_radius_m = 66898 where id = 34;
update public.counties set geofence_radius_m = 20760 where id = 35;
update public.counties set geofence_radius_m = 24045 where id = 36;
update public.counties set geofence_radius_m = 24760 where id = 37;
update public.counties set geofence_radius_m = 10709 where id = 38;
update public.counties set geofence_radius_m = 24906 where id = 39;
update public.counties set geofence_radius_m = 19297 where id = 40;
update public.counties set geofence_radius_m = 26832 where id = 41;
update public.counties set geofence_radius_m = 23421 where id = 42;
update public.counties set geofence_radius_m = 31229 where id = 43;
update public.counties set geofence_radius_m = 25476 where id = 44;
update public.counties set geofence_radius_m = 16361 where id = 45;
update public.counties set geofence_radius_m = 13470 where id = 46;
update public.counties set geofence_radius_m = 12023 where id = 47;
