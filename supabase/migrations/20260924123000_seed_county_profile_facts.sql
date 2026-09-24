-- Seed county profile facts for the Area / Elevation / Population /
-- Governor / Headquarters UI.
--
-- Sources:
-- - Area, county headquarters/capital and most governors: State Department
--   for Devolution "County Information", checked 2026-09-24.
-- - Meru governor: County Government of Meru / Kenya Gazette records for
--   Isaac Mutuma M'Ethingia, checked 2026-09-24.
-- - Population: KNBS 2019 Kenya Population and Housing Census Volume I.
-- - Elevation: GeoNames KE gazetteer DEM value for the headquarters town,
--   checked 2026-09-24.
--
-- Notes:
-- - `capital` is the existing counties column that represents county
--   headquarters/capital town.
-- - `elevation_m` means elevation at the county headquarters town, not the
--   county centroid, mean elevation, or highest point.

comment on column public.counties.capital is
  'County headquarters / capital town.';

comment on column public.counties.population is
  'County population from the 2019 Kenya Population and Housing Census.';

comment on column public.counties.area_km2 is
  'County area in square kilometres from the State Department for Devolution county information table.';

comment on column public.counties.governor_name is
  'Current county governor name, seeded from official county/devolution sources.';

comment on column public.counties.elevation_m is
  'Elevation in metres at the county headquarters town.';

update public.counties as counties
set
  area_km2 = facts.area_km2,
  population = facts.population,
  capital = facts.county_headquarters,
  governor_name = facts.governor_name,
  elevation_m = facts.elevation_m
from (
  values
    (1, 212.5::numeric, 1208333::bigint, 'Mombasa', 'Abdulswamad Shariff Nassir', 20::numeric),
    (2, 8270.3::numeric, 866820::bigint, 'Kwale', 'Fatuma Mohamed Achani', 403::numeric),
    (3, 12245.9::numeric, 1453787::bigint, 'Kilifi', 'Gideon Mung''aro', 24::numeric),
    (4, 35375.8::numeric, 315943::bigint, 'Hola', 'Dhadho Gaddae Godhana', 65::numeric),
    (5, 6497.7::numeric, 143920::bigint, 'Lamu', 'Issa Abdallah Timamy', 14::numeric),
    (6, 17083.9::numeric, 340671::bigint, 'Mwatate', 'Andrew Mwadime', 860::numeric),
    (7, 45720.2::numeric, 841353::bigint, 'Garissa', 'Nathif Jama', 147::numeric),
    (8, 55840.6::numeric, 781263::bigint, 'Wajir', 'Ahmed Abdullahi', 258::numeric),
    (9, 25797.7::numeric, 867457::bigint, 'Mandera', 'Mohamed Adan Khalif', 217::numeric),
    (10, 66923.1::numeric, 459785::bigint, 'Marsabit', 'Mohamud Ali', 1364::numeric),
    (11, 25336.1::numeric, 268002::bigint, 'Isiolo', 'Abdi Hassan Guyo', 1095::numeric),
    (12, 6930.1::numeric, 1545714::bigint, 'Meru', 'Isaac Mutuma M''Ethingia', 1579::numeric),
    (13, 2409.5::numeric, 393177::bigint, 'Kathwana', 'Muthomi Njuki', 722::numeric),
    (14, 2555.9::numeric, 608599::bigint, 'Embu', 'Cecily Mbarire', 1336::numeric),
    (15, 24385.1::numeric, 1136187::bigint, 'Kitui', 'Julius Malombe', 1154::numeric),
    (16, 5952.9::numeric, 1421932::bigint, 'Machakos', 'Wavinya Ndeti', 1619::numeric),
    (17, 8008.9::numeric, 987653::bigint, 'Wote', 'Mutula Kilonzo Jr', 1128::numeric),
    (18, 3107.7::numeric, 638289::bigint, 'Ol Kalou', 'Moses Badilisha Kiarie', 2348::numeric),
    (19, 2361::numeric, 759164::bigint, 'Nyeri', 'Mutahi Kahiga', 1812::numeric),
    (20, 1205.4::numeric, 610411::bigint, 'Kerugoya / Kutus', 'Anne Mumbi Waiguru', 1548::numeric),
    (21, 2325.8::numeric, 1056640::bigint, 'Murang''a', 'Irungu Kang''ata', 1318::numeric),
    (22, 2449.2::numeric, 2417735::bigint, 'Kiambu', 'Kimani Wamatangi', 1683::numeric),
    (23, 71597.8::numeric, 926976::bigint, 'Lodwar', 'Jeremiah Lomurkai', 500::numeric),
    (24, 8418.2::numeric, 621241::bigint, 'Kapenguria', 'Simon Kachapin', 2020::numeric),
    (25, 20182.5::numeric, 310327::bigint, 'Maralal', 'Jonathan Lati Leleliit', 1941::numeric),
    (26, 2469.9::numeric, 990341::bigint, 'Kitale', 'George Natembeya', 1900::numeric),
    (27, 2955.3::numeric, 1163186::bigint, 'Eldoret', 'Jonathan Bii', 2095::numeric),
    (28, 3049.7::numeric, 454480::bigint, 'Iten', 'Wisley Rotich Kipyegon', 2355::numeric),
    (29, 2884.5::numeric, 885711::bigint, 'Kapsabet', 'Stephen Kipyego Sang', 1998::numeric),
    (30, 11075.3::numeric, 666763::bigint, 'Kabarnet', 'Benjamin Cheboi', 2048::numeric),
    (31, 8696.1::numeric, 518560::bigint, 'Nanyuki', 'Joshua Irungu', 1951::numeric),
    (32, 7509.5::numeric, 2162202::bigint, 'Nakuru', 'Susan Kihika', 1802::numeric),
    (33, 17921.2::numeric, 1157873::bigint, 'Narok', 'Patrick Ole Ntutu', 1881::numeric),
    (34, 21292.7::numeric, 1117840::bigint, 'Kajiado', 'Joseph Jama Ole Lenku', 1725::numeric),
    (35, 2454.5::numeric, 901777::bigint, 'Kericho', 'Erick Kipkoech Mutai', 2002::numeric),
    (36, 1997.9::numeric, 875689::bigint, 'Bomet', 'Hillary Barchok', 1959::numeric),
    (37, 3033.8::numeric, 1867579::bigint, 'Kakamega', 'Fernandes Barasa', 1563::numeric),
    (38, 531.3::numeric, 590013::bigint, 'Vihiga', 'Wilber Khasilwa Ottichilo', 1669::numeric),
    (39, 2206.9::numeric, 1670570::bigint, 'Bungoma', 'Ken Lusaka', 1427::numeric),
    (40, 1628.4::numeric, 893681::bigint, 'Busia', 'Paul Otuoma', 1222::numeric),
    (41, 2496.1::numeric, 993183::bigint, 'Siaya', 'James Orengo', 1321::numeric),
    (42, 2009.5::numeric, 1155574::bigint, 'Kisumu', 'Peter Anyang'' Nyong''o', 1174::numeric),
    (43, 3154.7::numeric, 1131950::bigint, 'Homa Bay', 'Gladys Atieno Nyasuna Wanga', 1165::numeric),
    (44, 2586.4::numeric, 1116436::bigint, 'Migori', 'Ochillo Ayacko', 1382::numeric),
    (45, 1317.9::numeric, 1266860::bigint, 'Kisii', 'Paul Simba Arati', 1686::numeric),
    (46, 912.5::numeric, 605576::bigint, 'Nyamira', 'Amos Nyaribo Kimwomi', 2000::numeric),
    (47, 694.9::numeric, 4397073::bigint, 'Nairobi', 'Arthur Johnson Sakaja', 1684::numeric)
) as facts(id, area_km2, population, county_headquarters, governor_name, elevation_m)
where counties.id = facts.id;
