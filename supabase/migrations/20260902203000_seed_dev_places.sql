-- Dev places seed generated from data/places/dev_places_raw.json.
-- Source prose is not copied. Names, coordinates, IDs, licences and source
-- URLs are retained for review; summaries/descriptions are neutral dev copy.
-- Place images are Wikimedia Commons URLs plus attribution/licence metadata,
-- not downloaded binaries.

alter table public.places
  add column if not exists source_url text,
  add column if not exists external_id text,
  add column if not exists last_verified_at date;

create unique index if not exists places_source_external_id_idx
  on public.places (source, external_id)
  where external_id is not null;

with raw_places (
  name,
  type,
  summary,
  description,
  lat,
  lng,
  source,
  source_url,
  licence,
  external_id,
  last_verified_at
) as (
  values
    ('Aberdare National Park', 'park', 'Aberdare National Park - Protected landscape and wildlife destination.', 'Aberdare National Park is included in the dev places seed as a park candidate. The name, coordinates, and attribution come from the listed source; production copy should be editorially reviewed.', -0.38, 36.69916667, 'Wikidata', 'http://www.wikidata.org/entity/Q319356', 'CC0', 'Q319356', '2026-09-02'),
    ('Amboseli National Park', 'park', 'Amboseli National Park - Protected landscape and wildlife destination.', 'Amboseli National Park is included in the dev places seed as a park candidate. The name, coordinates, and attribution come from the listed source; production copy should be editorially reviewed.', -2.65, 37.25, 'Wikidata', 'http://www.wikidata.org/entity/Q458423', 'CC0', 'Q458423', '2026-09-02'),
    ('Arabuko Sokoke National Park', 'park', 'Arabuko Sokoke National Park - Protected landscape and wildlife destination.', 'Arabuko Sokoke National Park is included in the dev places seed as a park candidate. The name, coordinates, and attribution come from the listed source; production copy should be editorially reviewed.', -3.26666667, 39.81666667, 'Wikidata', 'http://www.wikidata.org/entity/Q624443', 'CC0', 'Q624443', '2026-09-02'),
    ('Bisanadi National Reserve', 'park', 'Bisanadi National Reserve - Protected landscape and wildlife destination.', 'Bisanadi National Reserve is included in the dev places seed as a park candidate. The name, coordinates, and attribution come from the listed source; production copy should be editorially reviewed.', 0.09, 38.41, 'Wikidata', 'http://www.wikidata.org/entity/Q28451065', 'CC0', 'Q28451065', '2026-09-02'),
    ('Bomas of Kenya', 'museum', 'Bomas of Kenya - Museum or cultural collection.', 'Bomas of Kenya is included in the dev places seed as a museum candidate. The name, coordinates, and attribution come from the listed source; production copy should be editorially reviewed.', -1.336878, 36.769123, 'Wikidata', 'http://www.wikidata.org/entity/Q225477', 'CC0', 'Q225477', '2026-09-02'),
    ('Buffalo Springs National Reserve', 'park', 'Buffalo Springs National Reserve - Protected landscape and wildlife destination.', 'Buffalo Springs National Reserve is included in the dev places seed as a park candidate. The name, coordinates, and attribution come from the listed source; production copy should be editorially reviewed.', 0.548333333, 37.595, 'Wikidata', 'http://www.wikidata.org/entity/Q1001903', 'CC0', 'Q1001903', '2026-09-02'),
    ('Central Island', 'shore', 'Central Island - Coastal, lake, or island destination.', 'Central Island is included in the dev places seed as a shore candidate. The name, coordinates, and attribution come from the listed source; production copy should be editorially reviewed.', 3.5, 36.05, 'Wikidata', 'http://www.wikidata.org/entity/Q1053880', 'CC0', 'Q1053880', '2026-09-02'),
    ('Chesowanja', 'culture', 'Chesowanja - Cultural or visitor landmark.', 'Chesowanja is included in the dev places seed as a culture candidate. The name, coordinates, and attribution come from the listed source; production copy should be editorially reviewed.', 0.65, 36.2, 'Wikidata', 'http://www.wikidata.org/entity/Q115590741', 'CC0', 'Q115590741', '2026-09-02'),
    ('Chyulu Hills', 'park', 'Chyulu Hills - Protected landscape and wildlife destination.', 'Chyulu Hills is included in the dev places seed as a park candidate. The name, coordinates, and attribution come from the listed source; production copy should be editorially reviewed.', -2.6, 37.85, 'Wikidata', 'http://www.wikidata.org/entity/Q5118629', 'CC0', 'Q5118629', '2026-09-02'),
    ('Enkapune Ya Muto', 'culture', 'Enkapune Ya Muto - Cultural or visitor landmark.', 'Enkapune Ya Muto is included in the dev places seed as a culture candidate. The name, coordinates, and attribution come from the listed source; production copy should be editorially reviewed.', 0.64638889, 36.05416667, 'Wikidata', 'http://www.wikidata.org/entity/Q4532001', 'CC0', 'Q4532001', '2026-09-02'),
    ('Fort Jesus Museum', 'museum', 'Fort Jesus Museum - Museum or cultural collection.', 'Fort Jesus Museum is included in the dev places seed as a museum candidate. The name, coordinates, and attribution come from the listed source; production copy should be editorially reviewed.', -4.071166666, 39.682055555, 'Wikidata', 'http://www.wikidata.org/entity/Q379080', 'CC0', 'Q379080', '2026-09-02'),
    ('Gogo Falls', 'culture', 'Gogo Falls - Cultural or visitor landmark.', 'Gogo Falls is included in the dev places seed as a culture candidate. The name, coordinates, and attribution come from the listed source; production copy should be editorially reviewed.', -0.9, 34.583333, 'Wikidata', 'http://www.wikidata.org/entity/Q24236335', 'CC0', 'Q24236335', '2026-09-02'),
    ('Hell''s Gate National Park', 'park', 'Hell''s Gate National Park - Protected landscape and wildlife destination.', 'Hell''s Gate National Park is included in the dev places seed as a park candidate. The name, coordinates, and attribution come from the listed source; production copy should be editorially reviewed.', -0.875404, 36.319114, 'Wikidata', 'http://www.wikidata.org/entity/Q1603133', 'CC0', 'Q1603133', '2026-09-02'),
    ('Hyrax Hill Prehistoric Site and Museum', 'museum', 'Hyrax Hill Prehistoric Site and Museum - Museum or cultural collection.', 'Hyrax Hill Prehistoric Site and Museum is included in the dev places seed as a museum candidate. The name, coordinates, and attribution come from the listed source; production copy should be editorially reviewed.', -0.2796, 36.1055, 'Wikidata', 'http://www.wikidata.org/entity/Q15036534', 'CC0', 'Q15036534', '2026-09-02'),
    ('Kabarnet Museum', 'museum', 'Kabarnet Museum - Museum or cultural collection.', 'Kabarnet Museum is included in the dev places seed as a museum candidate. The name, coordinates, and attribution come from the listed source; production copy should be editorially reviewed.', 0.491632, 35.7424, 'Wikidata', 'http://www.wikidata.org/entity/Q15036536', 'CC0', 'Q15036536', '2026-09-02'),
    ('Kapenguria Museum', 'museum', 'Kapenguria Museum - Museum or cultural collection.', 'Kapenguria Museum is included in the dev places seed as a museum candidate. The name, coordinates, and attribution come from the listed source; production copy should be editorially reviewed.', 1.26091, 35.0784, 'Wikidata', 'http://www.wikidata.org/entity/Q15036538', 'CC0', 'Q15036538', '2026-09-02'),
    ('Kapthurin', 'culture', 'Kapthurin - Cultural or visitor landmark.', 'Kapthurin is included in the dev places seed as a culture candidate. The name, coordinates, and attribution come from the listed source; production copy should be editorially reviewed.', 0.552958333, 35.972469444, 'Wikidata', 'http://www.wikidata.org/entity/Q6367291', 'CC0', 'Q6367291', '2026-09-02'),
    ('Karen Blixen Museum', 'museum', 'Karen Blixen Museum - Museum or cultural collection.', 'Karen Blixen Museum is included in the dev places seed as a museum candidate. The name, coordinates, and attribution come from the listed source; production copy should be editorially reviewed.', -1.35194444, 36.7125, 'Wikidata', 'http://www.wikidata.org/entity/Q367631', 'CC0', 'Q367631', '2026-09-02'),
    ('Kariandusi prehistoric site', 'heritage', 'Kariandusi prehistoric site - Historic or heritage site to visit.', 'Kariandusi prehistoric site is included in the dev places seed as a heritage candidate. The name, coordinates, and attribution come from the listed source; production copy should be editorially reviewed.', -0.7, 36.5, 'Wikidata', 'http://www.wikidata.org/entity/Q18392914', 'CC0', 'Q18392914', '2026-09-02'),
    ('Karsa, Kenya', 'culture', 'Karsa, Kenya - Cultural or visitor landmark.', 'Karsa, Kenya is included in the dev places seed as a culture candidate. The name, coordinates, and attribution come from the listed source; production copy should be editorially reviewed.', 3.17722222, 36.5425, 'Wikidata', 'http://www.wikidata.org/entity/Q22935827', 'CC0', 'Q22935827', '2026-09-02'),
    ('Kerio Valley National Reserve', 'park', 'Kerio Valley National Reserve - Protected landscape and wildlife destination.', 'Kerio Valley National Reserve is included in the dev places seed as a park candidate. The name, coordinates, and attribution come from the listed source; production copy should be editorially reviewed.', 0.640112, 35.608664, 'Wikidata', 'http://www.wikidata.org/entity/Q6393919', 'CC0', 'Q6393919', '2026-09-02'),
    ('Kigio Wildlife Conservancy', 'park', 'Kigio Wildlife Conservancy - Protected landscape and wildlife destination.', 'Kigio Wildlife Conservancy is included in the dev places seed as a park candidate. The name, coordinates, and attribution come from the listed source; production copy should be editorially reviewed.', -0.567417, 36.393371, 'Wikidata', 'http://www.wikidata.org/entity/Q6405950', 'CC0', 'Q6405950', '2026-09-02'),
    ('Kisite-Mpunguti Marine National Park', 'park', 'Kisite-Mpunguti Marine National Park - Protected landscape and wildlife destination.', 'Kisite-Mpunguti Marine National Park is included in the dev places seed as a park candidate. The name, coordinates, and attribution come from the listed source; production copy should be editorially reviewed.', -4.71388889, 39.36222222, 'Wikidata', 'http://www.wikidata.org/entity/Q1537314', 'CC0', 'Q1537314', '2026-09-02'),
    ('Kisumu Impala Sanctuary', 'park', 'Kisumu Impala Sanctuary - Protected landscape and wildlife destination.', 'Kisumu Impala Sanctuary is included in the dev places seed as a park candidate. The name, coordinates, and attribution come from the listed source; production copy should be editorially reviewed.', -0.125, 34.744444444, 'Wikidata', 'http://www.wikidata.org/entity/Q15238611', 'CC0', 'Q15238611', '2026-09-02'),
    ('Kisumu Museum', 'museum', 'Kisumu Museum - Museum or cultural collection.', 'Kisumu Museum is included in the dev places seed as a museum candidate. The name, coordinates, and attribution come from the listed source; production copy should be editorially reviewed.', -0.107615, 34.762693, 'Wikidata', 'http://www.wikidata.org/entity/Q3329722', 'CC0', 'Q3329722', '2026-09-02'),
    ('Kitale Museum', 'museum', 'Kitale Museum - Museum or cultural collection.', 'Kitale Museum is included in the dev places seed as a museum candidate. The name, coordinates, and attribution come from the listed source; production copy should be editorially reviewed.', 1.01343, 35.0054, 'Wikidata', 'http://www.wikidata.org/entity/Q15036543', 'CC0', 'Q15036543', '2026-09-02'),
    ('Koobi Fora', 'culture', 'Koobi Fora - Cultural or visitor landmark.', 'Koobi Fora is included in the dev places seed as a culture candidate. The name, coordinates, and attribution come from the listed source; production copy should be editorially reviewed.', 3.94777778, 36.18722222, 'Wikidata', 'http://www.wikidata.org/entity/Q1968136', 'CC0', 'Q1968136', '2026-09-02'),
    ('Kora National Park', 'park', 'Kora National Park - Protected landscape and wildlife destination.', 'Kora National Park is included in the dev places seed as a park candidate. The name, coordinates, and attribution come from the listed source; production copy should be editorially reviewed.', -0.20861111, 38.73611111, 'Wikidata', 'http://www.wikidata.org/entity/Q1784196', 'CC0', 'Q1784196', '2026-09-02'),
    ('Lake Nakuru National Park', 'park', 'Lake Nakuru National Park - Protected landscape and wildlife destination.', 'Lake Nakuru National Park is included in the dev places seed as a park candidate. The name, coordinates, and attribution come from the listed source; production copy should be editorially reviewed.', -0.36666667, 36.08333333, 'Wikidata', 'http://www.wikidata.org/entity/Q313071', 'CC0', 'Q313071', '2026-09-02'),
    ('Lamu Museum', 'museum', 'Lamu Museum - Museum or cultural collection.', 'Lamu Museum is included in the dev places seed as a museum candidate. The name, coordinates, and attribution come from the listed source; production copy should be editorially reviewed.', -2.26936111, 40.90216667, 'Wikidata', 'http://www.wikidata.org/entity/Q15036545', 'CC0', 'Q15036545', '2026-09-02'),
    ('Lewa Wildlife Conservancy', 'park', 'Lewa Wildlife Conservancy - Protected landscape and wildlife destination.', 'Lewa Wildlife Conservancy is included in the dev places seed as a park candidate. The name, coordinates, and attribution come from the listed source; production copy should be editorially reviewed.', 0.2, 37.41666667, 'Wikidata', 'http://www.wikidata.org/entity/Q6536088', 'CC0', 'Q6536088', '2026-09-02'),
    ('Lomekwi', 'culture', 'Lomekwi - Cultural or visitor landmark.', 'Lomekwi is included in the dev places seed as a culture candidate. The name, coordinates, and attribution come from the listed source; production copy should be editorially reviewed.', 3.91083, 35.8503, 'Wikidata', 'http://www.wikidata.org/entity/Q19833854', 'CC0', 'Q19833854', '2026-09-02'),
    ('Malindi Marine National Park', 'park', 'Malindi Marine National Park - Protected landscape and wildlife destination.', 'Malindi Marine National Park is included in the dev places seed as a park candidate. The name, coordinates, and attribution come from the listed source; production copy should be editorially reviewed.', -3.25560536, 40.14333944, 'Wikidata', 'http://www.wikidata.org/entity/Q1887395', 'CC0', 'Q1887395', '2026-09-02'),
    ('Malindi Museum', 'museum', 'Malindi Museum - Museum or cultural collection.', 'Malindi Museum is included in the dev places seed as a museum candidate. The name, coordinates, and attribution come from the listed source; production copy should be editorially reviewed.', -3.215922, 40.121813, 'Wikidata', 'http://www.wikidata.org/entity/Q15036547', 'CC0', 'Q15036547', '2026-09-02'),
    ('Malka Mari National Park', 'park', 'Malka Mari National Park - Protected landscape and wildlife destination.', 'Malka Mari National Park is included in the dev places seed as a park candidate. The name, coordinates, and attribution come from the listed source; production copy should be editorially reviewed.', 4.18499, 40.7712, 'Wikidata', 'http://www.wikidata.org/entity/Q19597810', 'CC0', 'Q19597810', '2026-09-02'),
    ('Marsabit National Park', 'park', 'Marsabit National Park - Protected landscape and wildlife destination.', 'Marsabit National Park is included in the dev places seed as a park candidate. The name, coordinates, and attribution come from the listed source; production copy should be editorially reviewed.', 2.38305556, 37.98305556, 'Wikidata', 'http://www.wikidata.org/entity/Q1516724', 'CC0', 'Q1516724', '2026-09-02'),
    ('Marsabit National Reserve', 'park', 'Marsabit National Reserve - Protected landscape and wildlife destination.', 'Marsabit National Reserve is included in the dev places seed as a park candidate. The name, coordinates, and attribution come from the listed source; production copy should be editorially reviewed.', 2.38305556, 37.98305556, 'Wikidata', 'http://www.wikidata.org/entity/Q25389795', 'CC0', 'Q25389795', '2026-09-02'),
    ('Meru Museum', 'museum', 'Meru Museum - Museum or cultural collection.', 'Meru Museum is included in the dev places seed as a museum candidate. The name, coordinates, and attribution come from the listed source; production copy should be editorially reviewed.', 0.0475, 37.6508, 'Wikidata', 'http://www.wikidata.org/entity/Q15036549', 'CC0', 'Q15036549', '2026-09-02'),
    ('Meru National Park', 'park', 'Meru National Park - Protected landscape and wildlife destination.', 'Meru National Park is included in the dev places seed as a park candidate. The name, coordinates, and attribution come from the listed source; production copy should be editorially reviewed.', -0.09361111, 38.20805556, 'Wikidata', 'http://www.wikidata.org/entity/Q1755551', 'CC0', 'Q1755551', '2026-09-02'),
    ('Meswa Bridge', 'culture', 'Meswa Bridge - Cultural or visitor landmark.', 'Meswa Bridge is included in the dev places seed as a culture candidate. The name, coordinates, and attribution come from the listed source; production copy should be editorially reviewed.', -0.136167, 35.205806, 'Wikidata', 'http://www.wikidata.org/entity/Q137160537', 'CC0', 'Q137160537', '2026-09-02'),
    ('Mida Creek', 'culture', 'Mida Creek - Cultural or visitor landmark.', 'Mida Creek is included in the dev places seed as a culture candidate. The name, coordinates, and attribution come from the listed source; production copy should be editorially reviewed.', -3.338125331, 39.964227676, 'Wikidata', 'http://www.wikidata.org/entity/Q124567488', 'CC0', 'Q124567488', '2026-09-02'),
    ('Mombasa Marine National Park and Reserve', 'park', 'Mombasa Marine National Park and Reserve - Protected landscape and wildlife destination.', 'Mombasa Marine National Park and Reserve is included in the dev places seed as a park candidate. The name, coordinates, and attribution come from the listed source; production copy should be editorially reviewed.', -4.06666667, 39.78333333, 'Wikidata', 'http://www.wikidata.org/entity/Q6897052', 'CC0', 'Q6897052', '2026-09-02'),
    ('Mount Elgon National Park', 'park', 'Mount Elgon National Park - Protected landscape and wildlife destination.', 'Mount Elgon National Park is included in the dev places seed as a park candidate. The name, coordinates, and attribution come from the listed source; production copy should be editorially reviewed.', 1.133333333, 34.583333333, 'Wikidata', 'http://www.wikidata.org/entity/Q1273335', 'CC0', 'Q1273335', '2026-09-02'),
    ('Mount Elgons national park', 'park', 'Mount Elgons national park - Protected landscape and wildlife destination.', 'Mount Elgons national park is included in the dev places seed as a park candidate. The name, coordinates, and attribution come from the listed source; production copy should be editorially reviewed.', 1.08333, 34.6167, 'Wikidata', 'http://www.wikidata.org/entity/Q10589778', 'CC0', 'Q10589778', '2026-09-02'),
    ('Mount Kenya National Park', 'park', 'Mount Kenya National Park - Protected landscape and wildlife destination.', 'Mount Kenya National Park is included in the dev places seed as a park candidate. The name, coordinates, and attribution come from the listed source; production copy should be editorially reviewed.', -0.123888888, 37.336666666, 'Wikidata', 'http://www.wikidata.org/entity/Q1639468', 'CC0', 'Q1639468', '2026-09-02'),
    ('Mount Longonot National Park', 'park', 'Mount Longonot National Park - Protected landscape and wildlife destination.', 'Mount Longonot National Park is included in the dev places seed as a park candidate. The name, coordinates, and attribution come from the listed source; production copy should be editorially reviewed.', -0.915278, 36.4569, 'Wikidata', 'http://www.wikidata.org/entity/Q3845176', 'CC0', 'Q3845176', '2026-09-02'),
    ('Nairobi National Museum', 'museum', 'Nairobi National Museum - Museum or cultural collection.', 'Nairobi National Museum is included in the dev places seed as a museum candidate. The name, coordinates, and attribution come from the listed source; production copy should be editorially reviewed.', -1.27404, 36.8145, 'Wikidata', 'http://www.wikidata.org/entity/Q2595707', 'CC0', 'Q2595707', '2026-09-02'),
    ('Nairobi National Park', 'park', 'Nairobi National Park - Protected landscape and wildlife destination.', 'Nairobi National Park is included in the dev places seed as a park candidate. The name, coordinates, and attribution come from the listed source; production copy should be editorially reviewed.', -1.373333333, 36.858888888, 'Wikidata', 'http://www.wikidata.org/entity/Q739993', 'CC0', 'Q739993', '2026-09-02'),
    ('Namoratunga', 'culture', 'Namoratunga - Cultural or visitor landmark.', 'Namoratunga is included in the dev places seed as a culture candidate. The name, coordinates, and attribution come from the listed source; production copy should be editorially reviewed.', 3.422778, 35.802778, 'Wikidata', 'http://www.wikidata.org/entity/Q1215326', 'CC0', 'Q1215326', '2026-09-02'),
    ('Narok Museum', 'museum', 'Narok Museum - Museum or cultural collection.', 'Narok Museum is included in the dev places seed as a museum candidate. The name, coordinates, and attribution come from the listed source; production copy should be editorially reviewed.', -1.08955, 35.8744, 'Wikidata', 'http://www.wikidata.org/entity/Q15036552', 'CC0', 'Q15036552', '2026-09-02'),
    ('Nyayanga', 'culture', 'Nyayanga - Cultural or visitor landmark.', 'Nyayanga is included in the dev places seed as a culture candidate. The name, coordinates, and attribution come from the listed source; production copy should be editorially reviewed.', -0.398483333, 34.451916666, 'Wikidata', 'http://www.wikidata.org/entity/Q123510295', 'CC0', 'Q123510295', '2026-09-02'),
    ('Ol Pejeta Conservancy', 'park', 'Ol Pejeta Conservancy - Protected landscape and wildlife destination.', 'Ol Pejeta Conservancy is included in the dev places seed as a park candidate. The name, coordinates, and attribution come from the listed source; production copy should be editorially reviewed.', 0.0, 37.0, 'Wikidata', 'http://www.wikidata.org/entity/Q7082831', 'CC0', 'Q7082831', '2026-09-02'),
    ('Olorgesailie', 'culture', 'Olorgesailie - Cultural or visitor landmark.', 'Olorgesailie is included in the dev places seed as a culture candidate. The name, coordinates, and attribution come from the listed source; production copy should be editorially reviewed.', -1.58, 36.45, 'Wikidata', 'http://www.wikidata.org/entity/Q3881916', 'CC0', 'Q3881916', '2026-09-02'),
    ('Panga ya Saidi', 'culture', 'Panga ya Saidi - Cultural or visitor landmark.', 'Panga ya Saidi is included in the dev places seed as a culture candidate. The name, coordinates, and attribution come from the listed source; production copy should be editorially reviewed.', -3.678611, 39.735833, 'Wikidata', 'http://www.wikidata.org/entity/Q53443604', 'CC0', 'Q53443604', '2026-09-02'),
    ('Peace, Love and Unity monument', 'heritage', 'Peace, Love and Unity monument - Historic or heritage site to visit.', 'Peace, Love and Unity monument is included in the dev places seed as a heritage candidate. The name, coordinates, and attribution come from the listed source; production copy should be editorially reviewed.', -1.289855555, 36.817763888, 'Wikidata', 'http://www.wikidata.org/entity/Q42843552', 'CC0', 'Q42843552', '2026-09-02'),
    ('Rabai Museum', 'museum', 'Rabai Museum - Museum or cultural collection.', 'Rabai Museum is included in the dev places seed as a museum candidate. The name, coordinates, and attribution come from the listed source; production copy should be editorially reviewed.', -3.92916, 39.5735, 'Wikidata', 'http://www.wikidata.org/entity/Q15036554', 'CC0', 'Q15036554', '2026-09-02'),
    ('Rahole National Reserve', 'park', 'Rahole National Reserve - Protected landscape and wildlife destination.', 'Rahole National Reserve is included in the dev places seed as a park candidate. The name, coordinates, and attribution come from the listed source; production copy should be editorially reviewed.', 0.05776, 39.23752, 'Wikidata', 'http://www.wikidata.org/entity/Q135113220', 'CC0', 'Q135113220', '2026-09-02'),
    ('Ruins of Gedi', 'culture', 'Ruins of Gedi - Cultural or visitor landmark.', 'Ruins of Gedi is included in the dev places seed as a culture candidate. The name, coordinates, and attribution come from the listed source; production copy should be editorially reviewed.', -3.309166666, 40.016666666, 'Wikidata', 'http://www.wikidata.org/entity/Q502518', 'CC0', 'Q502518', '2026-09-02'),
    ('Ruma National Park', 'park', 'Ruma National Park - Protected landscape and wildlife destination.', 'Ruma National Park is included in the dev places seed as a park candidate. The name, coordinates, and attribution come from the listed source; production copy should be editorially reviewed.', -0.61666667, 34.31666667, 'Wikidata', 'http://www.wikidata.org/entity/Q1549127', 'CC0', 'Q1549127', '2026-09-02'),
    ('Saadani National Park', 'park', 'Saadani National Park - Protected landscape and wildlife destination.', 'Saadani National Park is included in the dev places seed as a park candidate. The name, coordinates, and attribution come from the listed source; production copy should be editorially reviewed.', -6.0, 38.75, 'Wikidata', 'http://www.wikidata.org/entity/Q2032704', 'CC0', 'Q2032704', '2026-09-02'),
    ('Saiwa Swamp National Park', 'park', 'Saiwa Swamp National Park - Protected landscape and wildlife destination.', 'Saiwa Swamp National Park is included in the dev places seed as a park candidate. The name, coordinates, and attribution come from the listed source; production copy should be editorially reviewed.', 1.1, 35.11666667, 'Wikidata', 'http://www.wikidata.org/entity/Q1636810', 'CC0', 'Q1636810', '2026-09-02'),
    ('Shaba National Reserve', 'park', 'Shaba National Reserve - Protected landscape and wildlife destination.', 'Shaba National Reserve is included in the dev places seed as a park candidate. The name, coordinates, and attribution come from the listed source; production copy should be editorially reviewed.', 0.65, 37.83333333, 'Wikidata', 'http://www.wikidata.org/entity/Q762107', 'CC0', 'Q762107', '2026-09-02'),
    ('Shanga', 'culture', 'Shanga - Cultural or visitor landmark.', 'Shanga is included in the dev places seed as a culture candidate. The name, coordinates, and attribution come from the listed source; production copy should be editorially reviewed.', -2.1324, 41.0714, 'Wikidata', 'http://www.wikidata.org/entity/Q2646311', 'CC0', 'Q2646311', '2026-09-02'),
    ('Shompole Conservancy', 'park', 'Shompole Conservancy - Protected landscape and wildlife destination.', 'Shompole Conservancy is included in the dev places seed as a park candidate. The name, coordinates, and attribution come from the listed source; production copy should be editorially reviewed.', -2.02188, 36.045842, 'Wikidata', 'http://www.wikidata.org/entity/Q7500311', 'CC0', 'Q7500311', '2026-09-02'),
    ('Sibiloi National Park', 'park', 'Sibiloi National Park - Protected landscape and wildlife destination.', 'Sibiloi National Park is included in the dev places seed as a park candidate. The name, coordinates, and attribution come from the listed source; production copy should be editorially reviewed.', 3.960555555, 36.3425, 'Wikidata', 'http://www.wikidata.org/entity/Q1380559', 'CC0', 'Q1380559', '2026-09-02'),
    ('Tambach Museum', 'museum', 'Tambach Museum - Museum or cultural collection.', 'Tambach Museum is included in the dev places seed as a museum candidate. The name, coordinates, and attribution come from the listed source; production copy should be editorially reviewed.', 0.5961063, 35.5224139, 'Wikidata', 'http://www.wikidata.org/entity/Q15036557', 'CC0', 'Q15036557', '2026-09-02'),
    ('Thimlich Ohinga', 'culture', 'Thimlich Ohinga - Cultural or visitor landmark.', 'Thimlich Ohinga is included in the dev places seed as a culture candidate. The name, coordinates, and attribution come from the listed source; production copy should be editorially reviewed.', -0.891338055, 34.326106944, 'Wikidata', 'http://www.wikidata.org/entity/Q3524629', 'CC0', 'Q3524629', '2026-09-02'),
    ('Tsavo East National Park', 'park', 'Tsavo East National Park - Protected landscape and wildlife destination.', 'Tsavo East National Park is included in the dev places seed as a park candidate. The name, coordinates, and attribution come from the listed source; production copy should be editorially reviewed.', -2.778611111, 38.771666666, 'Wikidata', 'http://www.wikidata.org/entity/Q1368818', 'CC0', 'Q1368818', '2026-09-02'),
    ('Tsavo West National Park', 'park', 'Tsavo West National Park - Protected landscape and wildlife destination.', 'Tsavo West National Park is included in the dev places seed as a park candidate. The name, coordinates, and attribution come from the listed source; production copy should be editorially reviewed.', -3.31666667, 38.13333333, 'Wikidata', 'http://www.wikidata.org/entity/Q1602738', 'CC0', 'Q1602738', '2026-09-02'),
    ('Ungwana', 'culture', 'Ungwana - Cultural or visitor landmark.', 'Ungwana is included in the dev places seed as a culture candidate. The name, coordinates, and attribution come from the listed source; production copy should be editorially reviewed.', -2.53333333, 40.53333333, 'Wikidata', 'http://www.wikidata.org/entity/Q2493673', 'CC0', 'Q2493673', '2026-09-02'),
    ('Urewe', 'culture', 'Urewe - Cultural or visitor landmark.', 'Urewe is included in the dev places seed as a culture candidate. The name, coordinates, and attribution come from the listed source; production copy should be editorially reviewed.', -0.04743, 34.33759, 'Wikidata', 'http://www.wikidata.org/entity/Q3552272', 'CC0', 'Q3552272', '2026-09-02'),
    ('Wajir Museum', 'museum', 'Wajir Museum - Museum or cultural collection.', 'Wajir Museum is included in the dev places seed as a museum candidate. The name, coordinates, and attribution come from the listed source; production copy should be editorially reviewed.', 1.74696553, 40.064513124, 'Wikidata', 'http://www.wikidata.org/entity/Q110235766', 'CC0', 'Q110235766', '2026-09-02'),
    ('Watamu Marine National Park', 'park', 'Watamu Marine National Park - Protected landscape and wildlife destination.', 'Watamu Marine National Park is included in the dev places seed as a park candidate. The name, coordinates, and attribution come from the listed source; production copy should be editorially reviewed.', -3.36777778, 40.01638889, 'Wikidata', 'http://www.wikidata.org/entity/Q1107102', 'CC0', 'Q1107102', '2026-09-02'),
    ('Wray Memorial Museum', 'museum', 'Wray Memorial Museum - Museum or cultural collection.', 'Wray Memorial Museum is included in the dev places seed as a museum candidate. The name, coordinates, and attribution come from the listed source; production copy should be editorially reviewed.', -3.509035, 38.575439, 'Wikidata', 'http://www.wikidata.org/entity/Q110269360', 'CC0', 'Q110269360', '2026-09-02')
),
normalized as (
  select
    raw_places.*,
    extensions.ST_SetSRID(
      extensions.ST_MakePoint(raw_places.lng, raw_places.lat),
      4326
    ) as location
  from raw_places
),
county_matched as (
  select distinct on (normalized.source, normalized.external_id)
    counties.id as county_id,
    normalized.name,
    normalized.type,
    normalized.summary,
    normalized.description,
    normalized.location,
    normalized.source,
    normalized.source_url,
    normalized.licence,
    normalized.external_id,
    normalized.last_verified_at::date
  from normalized
  join public.counties
    on extensions.ST_Covers(counties.geometry, normalized.location)
  order by normalized.source, normalized.external_id, counties.id
)
insert into public.places (
  county_id,
  name,
  type,
  summary,
  description,
  location,
  source,
  source_url,
  licence,
  external_id,
  last_verified_at
)
select
  county_id,
  name,
  type,
  summary,
  description,
  location,
  source,
  source_url,
  licence,
  external_id,
  last_verified_at
from county_matched
on conflict (source, external_id) where external_id is not null do update set
  county_id = excluded.county_id,
  name = excluded.name,
  type = excluded.type,
  summary = excluded.summary,
  description = excluded.description,
  location = excluded.location,
  source_url = excluded.source_url,
  licence = excluded.licence,
  last_verified_at = excluded.last_verified_at;

create table if not exists public.place_images (
  id uuid primary key default gen_random_uuid(),
  place_id uuid not null references public.places (id) on delete cascade,
  sort_order integer not null default 0,
  image_url text not null,
  thumbnail_url text not null,
  width integer,
  height integer,
  source text not null,
  source_url text not null,
  licence text not null,
  licence_url text,
  attribution text,
  external_id text not null,
  last_verified_at date,
  created_at timestamptz not null default now(),
  unique (source, external_id)
);

alter table public.place_images enable row level security;

create policy "Anyone signed in can read place images"
  on public.place_images
  for select
  to authenticated
  using (true);

with raw_place_images (
  place_source,
  place_external_id,
  sort_order,
  image_url,
  thumbnail_url,
  width,
  height,
  source,
  source_url,
  licence,
  licence_url,
  attribution,
  external_id,
  last_verified_at
) as (
  values
    ('Wikidata', 'Q319356', 0, 'https://upload.wikimedia.org/wikipedia/commons/b/b7/Aberdare_gate.JPG?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=original', 'https://thumb.wikimedia.org/wikipedia/commons/thumb/b/b7/Aberdare_gate.JPG/1280px-Aberdare_gate.JPG?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail', 2256, 1496, 'Wikimedia Commons', 'https://commons.wikimedia.org/wiki/File:Aberdare_gate.JPG', 'CC BY-SA 3.0', 'https://creativecommons.org/licenses/by-sa/3.0', 'Yumiko254', 'Aberdare gate.JPG', '2026-09-02'),
    ('Wikidata', 'Q458423', 0, 'https://upload.wikimedia.org/wikipedia/commons/5/52/Elephants_Kili_2.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=original', 'https://thumb.wikimedia.org/wikipedia/commons/thumb/5/52/Elephants_Kili_2.jpg/1280px-Elephants_Kili_2.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail', 1600, 1200, 'Wikimedia Commons', 'https://commons.wikimedia.org/wiki/File:Elephants_Kili_2.jpg', 'CC BY-SA 2.5', 'https://creativecommons.org/licenses/by-sa/2.5', 'M. Disdero', 'Elephants Kili 2.jpg', '2026-09-02'),
    ('Wikidata', 'Q624443', 0, 'https://upload.wikimedia.org/wikipedia/commons/0/00/The_road_in_Arabuko_Sokoke_Forest_-_panoramio.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=original', 'https://thumb.wikimedia.org/wikipedia/commons/thumb/0/00/The_road_in_Arabuko_Sokoke_Forest_-_panoramio.jpg/1280px-The_road_in_Arabuko_Sokoke_Forest_-_panoramio.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail', 3472, 2614, 'Wikimedia Commons', 'https://commons.wikimedia.org/wiki/File:The_road_in_Arabuko_Sokoke_Forest_-_panoramio.jpg', 'CC BY 3.0', 'https://creativecommons.org/licenses/by/3.0', 'Николай Максимович', 'The road in Arabuko Sokoke Forest - panoramio.jpg', '2026-09-02'),
    ('Wikidata', 'Q225477', 0, 'https://upload.wikimedia.org/wikipedia/commons/4/4e/Kamba_village_01.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=original', 'https://thumb.wikimedia.org/wikipedia/commons/thumb/4/4e/Kamba_village_01.jpg/1280px-Kamba_village_01.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail', 3008, 2000, 'Wikimedia Commons', 'https://commons.wikimedia.org/wiki/File:Kamba_village_01.jpg', 'CC BY-SA 4.0', 'https://creativecommons.org/licenses/by-sa/4.0', 'Alexander Leisser', 'Kamba village 01.jpg', '2026-09-02'),
    ('Wikidata', 'Q1001903', 0, 'https://upload.wikimedia.org/wikipedia/commons/1/19/Buffalo_Springs_NP_-_panoramio.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=original', 'https://upload.wikimedia.org/wikipedia/commons/1/19/Buffalo_Springs_NP_-_panoramio.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail_unscaled', 900, 600, 'Wikimedia Commons', 'https://commons.wikimedia.org/wiki/File:Buffalo_Springs_NP_-_panoramio.jpg', 'CC BY 3.0', 'https://creativecommons.org/licenses/by/3.0', 'Banja-Frans Mulder', 'Buffalo Springs NP - panoramio.jpg', '2026-09-02'),
    ('Wikidata', 'Q1053880', 0, 'https://upload.wikimedia.org/wikipedia/commons/0/07/Kenya_Aerial_2009-08-27_14-27-32.JPG?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=original', 'https://thumb.wikimedia.org/wikipedia/commons/thumb/0/07/Kenya_Aerial_2009-08-27_14-27-32.JPG/1280px-Kenya_Aerial_2009-08-27_14-27-32.JPG?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail', 2373, 1601, 'Wikimedia Commons', 'https://commons.wikimedia.org/wiki/File:Kenya_Aerial_2009-08-27_14-27-32.JPG', 'CC BY-SA 3.0', 'https://creativecommons.org/licenses/by-sa/3.0', 'Hansueli Krapf', 'Kenya Aerial 2009-08-27 14-27-32.JPG', '2026-09-02'),
    ('Wikidata', 'Q5118629', 0, 'https://upload.wikimedia.org/wikipedia/commons/0/09/Tsavo_West_National_Park%2C_Kenya_%2853493414096%29.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=original', 'https://thumb.wikimedia.org/wikipedia/commons/thumb/0/09/Tsavo_West_National_Park%2C_Kenya_%2853493414096%29.jpg/1280px-Tsavo_West_National_Park%2C_Kenya_%2853493414096%29.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail', 5658, 3772, 'Wikimedia Commons', 'https://commons.wikimedia.org/wiki/File:Tsavo_West_National_Park%2C_Kenya_%2853493414096%29.jpg', 'CC BY 2.0', 'https://creativecommons.org/licenses/by/2.0', 'Ninara', 'Tsavo West National Park, Kenya (53493414096).jpg', '2026-09-02'),
    ('Wikidata', 'Q379080', 0, 'https://upload.wikimedia.org/wikipedia/commons/1/1e/Fort_JesusMombasa.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=original', 'https://upload.wikimedia.org/wikipedia/commons/1/1e/Fort_JesusMombasa.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail_unscaled', 425, 319, 'Wikimedia Commons', 'https://commons.wikimedia.org/wiki/File:Fort_JesusMombasa.jpg', 'CC BY-SA 3.0', 'http://creativecommons.org/licenses/by-sa/3.0/', 'The original uploader was Zeljko at Croatian Wikipedia.', 'Fort JesusMombasa.jpg', '2026-09-02'),
    ('Wikidata', 'Q1603133', 0, 'https://upload.wikimedia.org/wikipedia/commons/5/54/Hell%27s_Gate_Gorge_%282294202692%29.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=original', 'https://upload.wikimedia.org/wikipedia/commons/5/54/Hell%27s_Gate_Gorge_%282294202692%29.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail_unscaled', 1024, 681, 'Wikimedia Commons', 'https://commons.wikimedia.org/wiki/File:Hell%27s_Gate_Gorge_%282294202692%29.jpg', 'CC BY 2.0', 'https://creativecommons.org/licenses/by/2.0', 'Nao Iizuka from Tokyo, Japan', 'Hell''s Gate Gorge (2294202692).jpg', '2026-09-02'),
    ('Wikidata', 'Q15036534', 0, 'https://upload.wikimedia.org/wikipedia/commons/3/38/Hyrax_Hill_Museum.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=original', 'https://upload.wikimedia.org/wikipedia/commons/3/38/Hyrax_Hill_Museum.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail_unscaled', 377, 215, 'Wikimedia Commons', 'https://commons.wikimedia.org/wiki/File:Hyrax_Hill_Museum.jpg', 'CC BY-SA 3.0', 'https://creativecommons.org/licenses/by-sa/3.0', 'Awinda', 'Hyrax Hill Museum.jpg', '2026-09-02'),
    ('Wikidata', 'Q367631', 0, 'https://upload.wikimedia.org/wikipedia/commons/3/34/Karen_Blixen_House%2C_Nairobi%2C_Kenya_%2822288985045%29.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=original', 'https://thumb.wikimedia.org/wikipedia/commons/thumb/3/34/Karen_Blixen_House%2C_Nairobi%2C_Kenya_%2822288985045%29.jpg/1280px-Karen_Blixen_House%2C_Nairobi%2C_Kenya_%2822288985045%29.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail', 7360, 4565, 'Wikimedia Commons', 'https://commons.wikimedia.org/wiki/File:Karen_Blixen_House%2C_Nairobi%2C_Kenya_%2822288985045%29.jpg', 'CC BY-SA 2.0', 'https://creativecommons.org/licenses/by-sa/2.0', 'Rod Waddington', 'Karen Blixen House, Nairobi, Kenya (22288985045).jpg', '2026-09-02'),
    ('Wikidata', 'Q22935827', 0, 'https://upload.wikimedia.org/wikipedia/commons/2/2f/Karsa_basalt_columns.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=original', 'https://thumb.wikimedia.org/wikipedia/commons/thumb/2/2f/Karsa_basalt_columns.jpg/1280px-Karsa_basalt_columns.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail', 4307, 2871, 'Wikimedia Commons', 'https://commons.wikimedia.org/wiki/File:Karsa_basalt_columns.jpg', 'CC BY-SA 4.0', 'https://creativecommons.org/licenses/by-sa/4.0', 'Darouet', 'Karsa basalt columns.jpg', '2026-09-02'),
    ('Wikidata', 'Q6405950', 0, 'https://upload.wikimedia.org/wikipedia/commons/e/e0/Rhino_up_close%2C_Kigio_Conservancy%2C_Kenya.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=original', 'https://thumb.wikimedia.org/wikipedia/commons/thumb/e/e0/Rhino_up_close%2C_Kigio_Conservancy%2C_Kenya.jpg/1280px-Rhino_up_close%2C_Kigio_Conservancy%2C_Kenya.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail', 3597, 2300, 'Wikimedia Commons', 'https://commons.wikimedia.org/wiki/File:Rhino_up_close%2C_Kigio_Conservancy%2C_Kenya.jpg', 'CC BY 2.0', 'https://creativecommons.org/licenses/by/2.0', 'Paul Mannix', 'Rhino up close, Kigio Conservancy, Kenya.jpg', '2026-09-02'),
    ('Wikidata', 'Q1537314', 0, 'https://upload.wikimedia.org/wikipedia/commons/6/62/Kisiti_med_delfiner_lo.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=original', 'https://upload.wikimedia.org/wikipedia/commons/6/62/Kisiti_med_delfiner_lo.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail_unscaled', 731, 480, 'Wikimedia Commons', 'https://commons.wikimedia.org/wiki/File:Kisiti_med_delfiner_lo.jpg', 'CC BY-SA 3.0', 'https://creativecommons.org/licenses/by-sa/3.0', 'Rotsee2', 'Kisiti med delfiner lo.jpg', '2026-09-02'),
    ('Wikidata', 'Q3329722', 0, 'https://upload.wikimedia.org/wikipedia/commons/2/21/Kisumu-Ber_gi_dala4.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=original', 'https://upload.wikimedia.org/wikipedia/commons/2/21/Kisumu-Ber_gi_dala4.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail_unscaled', 720, 540, 'Wikimedia Commons', 'https://commons.wikimedia.org/wiki/File:Kisumu-Ber_gi_dala4.jpg', 'CC BY-SA 3.0', 'https://creativecommons.org/licenses/by-sa/3.0', 'Omondi', 'Kisumu-Ber gi dala4.jpg', '2026-09-02'),
    ('Wikidata', 'Q15036543', 0, 'https://upload.wikimedia.org/wikipedia/commons/b/b4/DSC00661_Kitale_Museum_2019.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=original', 'https://upload.wikimedia.org/wikipedia/commons/b/b4/DSC00661_Kitale_Museum_2019.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail_unscaled', 1200, 900, 'Wikimedia Commons', 'https://commons.wikimedia.org/wiki/File:DSC00661_Kitale_Museum_2019.jpg', 'CC BY-SA 4.0', 'https://creativecommons.org/licenses/by-sa/4.0', 'Leovdvxxx', 'DSC00661 Kitale Museum 2019.jpg', '2026-09-02'),
    ('Wikidata', 'Q1968136', 0, 'https://upload.wikimedia.org/wikipedia/commons/c/cf/National_Museums_of_Kenya_Koobi_Fora_Hq.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=original', 'https://upload.wikimedia.org/wikipedia/commons/c/cf/National_Museums_of_Kenya_Koobi_Fora_Hq.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail_unscaled', 1025, 684, 'Wikimedia Commons', 'https://commons.wikimedia.org/wiki/File:National_Museums_of_Kenya_Koobi_Fora_Hq.jpg', 'CC BY-SA 3.0', 'https://creativecommons.org/licenses/by-sa/3.0', 'Maina Kiarie, Enzi Museum', 'National Museums of Kenya Koobi Fora Hq.jpg', '2026-09-02'),
    ('Wikidata', 'Q1784196', 0, 'https://upload.wikimedia.org/wikipedia/commons/5/5a/DM-SD-02-04679.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=original', 'https://upload.wikimedia.org/wikipedia/commons/5/5a/DM-SD-02-04679.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail_unscaled', 1120, 800, 'Wikimedia Commons', 'https://commons.wikimedia.org/wiki/File:DM-SD-02-04679.jpg', 'Public domain', null, 'SGT R. A. WARD, USMC', 'DM-SD-02-04679.jpg', '2026-09-02'),
    ('Wikidata', 'Q313071', 0, 'https://upload.wikimedia.org/wikipedia/commons/a/ab/Flamingoes-Lake_Nakuru.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=original', 'https://thumb.wikimedia.org/wikipedia/commons/thumb/a/ab/Flamingoes-Lake_Nakuru.jpg/1280px-Flamingoes-Lake_Nakuru.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail', 1920, 1080, 'Wikimedia Commons', 'https://commons.wikimedia.org/wiki/File:Flamingoes-Lake_Nakuru.jpg', 'CC BY-SA 4.0', 'https://creativecommons.org/licenses/by-sa/4.0', 'Lyfec', 'Flamingoes-Lake Nakuru.jpg', '2026-09-02'),
    ('Wikidata', 'Q15036545', 0, 'https://upload.wikimedia.org/wikipedia/commons/2/28/Lamu_Museum.JPG?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=original', 'https://thumb.wikimedia.org/wikipedia/commons/thumb/2/28/Lamu_Museum.JPG/1280px-Lamu_Museum.JPG?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail', 1600, 1200, 'Wikimedia Commons', 'https://commons.wikimedia.org/wiki/File:Lamu_Museum.JPG', 'CC BY-SA 3.0', 'https://creativecommons.org/licenses/by-sa/3.0', 'Krg This photo was taken by Karl Ragnar Gjertsen. Please credit this photo Karl Ragnar Gjertsen in the immediate vicinity of the image.', 'Lamu Museum.JPG', '2026-09-02'),
    ('Wikidata', 'Q19833854', 0, 'https://upload.wikimedia.org/wikipedia/commons/9/98/Lake_turkana_satellite.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=original', 'https://upload.wikimedia.org/wikipedia/commons/9/98/Lake_turkana_satellite.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail_unscaled', 992, 735, 'Wikimedia Commons', 'https://commons.wikimedia.org/wiki/File:Lake_turkana_satellite.jpg', 'Public domain', null, 'Photograph: NASA', 'Lake turkana satellite.jpg', '2026-09-02'),
    ('Wikidata', 'Q1887395', 0, 'https://upload.wikimedia.org/wikipedia/commons/8/87/Malindi_Marine_National_Park_02.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=original', 'https://thumb.wikimedia.org/wikipedia/commons/thumb/8/87/Malindi_Marine_National_Park_02.jpg/1280px-Malindi_Marine_National_Park_02.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail', 3488, 2616, 'Wikimedia Commons', 'https://commons.wikimedia.org/wiki/File:Malindi_Marine_National_Park_02.jpg', 'CC BY-SA 3.0', 'https://creativecommons.org/licenses/by-sa/3.0', 'Nicor', 'Malindi Marine National Park 02.jpg', '2026-09-02'),
    ('Wikidata', 'Q15036547', 0, 'https://upload.wikimedia.org/wikipedia/commons/4/4a/Malindi_coelacanth.JPG?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=original', 'https://thumb.wikimedia.org/wikipedia/commons/thumb/4/4a/Malindi_coelacanth.JPG/1280px-Malindi_coelacanth.JPG?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail', 3264, 2448, 'Wikimedia Commons', 'https://commons.wikimedia.org/wiki/File:Malindi_coelacanth.JPG', 'CC BY-SA 4.0', 'https://creativecommons.org/licenses/by-sa/4.0', 'Ruslik0', 'Malindi coelacanth.JPG', '2026-09-02'),
    ('Wikidata', 'Q1516724', 0, 'https://upload.wikimedia.org/wikipedia/commons/f/f1/Marsabit-Moyale_Rd.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=original', 'https://thumb.wikimedia.org/wikipedia/commons/thumb/f/f1/Marsabit-Moyale_Rd.jpg/1280px-Marsabit-Moyale_Rd.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail', 2560, 1920, 'Wikimedia Commons', 'https://commons.wikimedia.org/wiki/File:Marsabit-Moyale_Rd.jpg', 'CC BY 2.0', 'https://creativecommons.org/licenses/by/2.0', 'Lindsey Nicholson', 'Marsabit-Moyale Rd.jpg', '2026-09-02'),
    ('Wikidata', 'Q1755551', 0, 'https://upload.wikimedia.org/wikipedia/commons/6/67/Mt_Meru.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=original', 'https://thumb.wikimedia.org/wikipedia/commons/thumb/6/67/Mt_Meru.jpg/1280px-Mt_Meru.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail', 2272, 1704, 'Wikimedia Commons', 'https://commons.wikimedia.org/wiki/File:Mt_Meru.jpg', 'CC BY 2.0', 'https://creativecommons.org/licenses/by/2.0', 'neiljs', 'Mt Meru.jpg', '2026-09-02'),
    ('Wikidata', 'Q6897052', 0, 'https://upload.wikimedia.org/wikipedia/commons/c/c5/Wooden_boat_off-shore_in_Mombasa%27s_Marine_Park.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=original', 'https://thumb.wikimedia.org/wikipedia/commons/thumb/c/c5/Wooden_boat_off-shore_in_Mombasa%27s_Marine_Park.jpg/1280px-Wooden_boat_off-shore_in_Mombasa%27s_Marine_Park.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail', 2048, 1365, 'Wikimedia Commons', 'https://commons.wikimedia.org/wiki/File:Wooden_boat_off-shore_in_Mombasa%27s_Marine_Park.jpg', 'CC BY 2.0', 'https://creativecommons.org/licenses/by/2.0', 'McKay Savage from London, UK', 'Wooden boat off-shore in Mombasa''s Marine Park.jpg', '2026-09-02'),
    ('Wikidata', 'Q1273335', 0, 'https://upload.wikimedia.org/wikipedia/commons/9/9a/Mount_Elgon_Forest.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=original', 'https://thumb.wikimedia.org/wikipedia/commons/thumb/9/9a/Mount_Elgon_Forest.jpg/1280px-Mount_Elgon_Forest.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail', 1417, 1063, 'Wikimedia Commons', 'https://commons.wikimedia.org/wiki/File:Mount_Elgon_Forest.jpg', 'CC BY-SA 2.0', 'https://creativecommons.org/licenses/by-sa/2.0', 'Kristina Just, Copenhagen (https://www.flickr.com/photos/kristinajust/)', 'Mount Elgon Forest.jpg', '2026-09-02'),
    ('Wikidata', 'Q1639468', 0, 'https://upload.wikimedia.org/wikipedia/commons/e/e9/Mount_Kenya_and_the_Gregory_Glacier.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=original', 'https://upload.wikimedia.org/wikipedia/commons/e/e9/Mount_Kenya_and_the_Gregory_Glacier.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail_unscaled', 1174, 778, 'Wikimedia Commons', 'https://commons.wikimedia.org/wiki/File:Mount_Kenya_and_the_Gregory_Glacier.jpg', 'CC BY-SA 4.0', 'https://creativecommons.org/licenses/by-sa/4.0', 'Ronaldcameron', 'Mount Kenya and the Gregory Glacier.jpg', '2026-09-02'),
    ('Wikidata', 'Q2595707', 0, 'https://upload.wikimedia.org/wikipedia/commons/3/37/At_Nairobi_National_Museum_2025_005.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=original', 'https://thumb.wikimedia.org/wikipedia/commons/thumb/3/37/At_Nairobi_National_Museum_2025_005.jpg/1280px-At_Nairobi_National_Museum_2025_005.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail', 6960, 4640, 'Wikimedia Commons', 'https://commons.wikimedia.org/wiki/File:At_Nairobi_National_Museum_2025_005.jpg', 'CC BY-SA 4.0', 'https://creativecommons.org/licenses/by-sa/4.0', 'Photograph by Mike Peel (www.mikepeel.net).', 'At Nairobi National Museum 2025 005.jpg', '2026-09-02'),
    ('Wikidata', 'Q739993', 0, 'https://upload.wikimedia.org/wikipedia/commons/a/ac/A_lone_giraffe_in_Nairobi_National_Park.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=original', 'https://upload.wikimedia.org/wikipedia/commons/a/ac/A_lone_giraffe_in_Nairobi_National_Park.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail_unscaled', 768, 576, 'Wikimedia Commons', 'https://commons.wikimedia.org/wiki/File:A_lone_giraffe_in_Nairobi_National_Park.jpg', 'CC BY-SA 3.0', 'http://creativecommons.org/licenses/by-sa/3.0/', 'The original uploader was Mkimemia at English Wikipedia.', 'A lone giraffe in Nairobi National Park.jpg', '2026-09-02'),
    ('Wikidata', 'Q1215326', 0, 'https://upload.wikimedia.org/wikipedia/commons/4/44/Namoratunga_in_Turkana%2C_Kenya.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=original', 'https://upload.wikimedia.org/wikipedia/commons/4/44/Namoratunga_in_Turkana%2C_Kenya.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail_unscaled', 450, 300, 'Wikimedia Commons', 'https://commons.wikimedia.org/wiki/File:Namoratunga_in_Turkana%2C_Kenya.jpg', 'CC BY-SA 4.0', 'https://creativecommons.org/licenses/by-sa/4.0', 'Darouet', 'Namoratunga in Turkana, Kenya.jpg', '2026-09-02'),
    ('Wikidata', 'Q7082831', 0, 'https://upload.wikimedia.org/wikipedia/commons/e/e2/Ceratotherium_simum_cottoni_-Ol_Pejeta_Conservancy%2C_Kenya.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=original', 'https://thumb.wikimedia.org/wikipedia/commons/thumb/e/e2/Ceratotherium_simum_cottoni_-Ol_Pejeta_Conservancy%2C_Kenya.jpg/1280px-Ceratotherium_simum_cottoni_-Ol_Pejeta_Conservancy%2C_Kenya.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail', 1920, 1080, 'Wikimedia Commons', 'https://commons.wikimedia.org/wiki/File:Ceratotherium_simum_cottoni_-Ol_Pejeta_Conservancy%2C_Kenya.jpg', 'CC BY 3.0', 'https://creativecommons.org/licenses/by/3.0', 'Lengai101', 'Ceratotherium simum cottoni -Ol Pejeta Conservancy, Kenya.jpg', '2026-09-02'),
    ('Wikidata', 'Q3881916', 0, 'https://upload.wikimedia.org/wikipedia/commons/c/c7/Olorgesailiesite1993%282%29.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=original', 'https://thumb.wikimedia.org/wikipedia/commons/thumb/c/c7/Olorgesailiesite1993%282%29.jpg/1280px-Olorgesailiesite1993%282%29.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail', 4456, 3042, 'Wikimedia Commons', 'https://commons.wikimedia.org/wiki/File:Olorgesailiesite1993%282%29.jpg', 'CC BY-SA 3.0', 'https://creativecommons.org/licenses/by-sa/3.0', 'Rossignol Benoît', 'Olorgesailiesite1993(2).jpg', '2026-09-02'),
    ('Wikidata', 'Q53443604', 0, 'https://upload.wikimedia.org/wikipedia/commons/7/79/Panga_ya_Saidi_archaeological_site.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=original', 'https://thumb.wikimedia.org/wikipedia/commons/thumb/7/79/Panga_ya_Saidi_archaeological_site.jpg/1280px-Panga_ya_Saidi_archaeological_site.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail', 3456, 5184, 'Wikimedia Commons', 'https://commons.wikimedia.org/wiki/File:Panga_ya_Saidi_archaeological_site.jpg', 'CC BY-SA 4.0', 'https://creativecommons.org/licenses/by-sa/4.0', 'Ceri Shipton', 'Panga ya Saidi archaeological site.jpg', '2026-09-02'),
    ('Wikidata', 'Q42843552', 0, 'https://upload.wikimedia.org/wikipedia/commons/7/73/Peace%2C_Love_and_Unity_monument%2C_2025_%2801%29.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=original', 'https://thumb.wikimedia.org/wikipedia/commons/thumb/7/73/Peace%2C_Love_and_Unity_monument%2C_2025_%2801%29.jpg/1280px-Peace%2C_Love_and_Unity_monument%2C_2025_%2801%29.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail', 3776, 2520, 'Wikimedia Commons', 'https://commons.wikimedia.org/wiki/File:Peace%2C_Love_and_Unity_monument%2C_2025_%2801%29.jpg', 'CC BY-SA 4.0', 'https://creativecommons.org/licenses/by-sa/4.0', 'Bahnfrend', 'Peace, Love and Unity monument, 2025 (01).jpg', '2026-09-02'),
    ('Wikidata', 'Q502518', 0, 'https://upload.wikimedia.org/wikipedia/commons/5/55/Great_Mosque_of_Gede.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=original', 'https://thumb.wikimedia.org/wikipedia/commons/thumb/5/55/Great_Mosque_of_Gede.jpg/1280px-Great_Mosque_of_Gede.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail', 1984, 1488, 'Wikimedia Commons', 'https://commons.wikimedia.org/wiki/File:Great_Mosque_of_Gede.jpg', 'CC BY-SA 3.0', 'http://creativecommons.org/licenses/by-sa/3.0/', 'Mgiganteus', 'Great Mosque of Gede.jpg', '2026-09-02'),
    ('Wikidata', 'Q1549127', 0, 'https://upload.wikimedia.org/wikipedia/commons/a/a5/Girafe_de_Rostchild.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=original', 'https://upload.wikimedia.org/wikipedia/commons/a/a5/Girafe_de_Rostchild.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail_unscaled', 800, 533, 'Wikimedia Commons', 'https://commons.wikimedia.org/wiki/File:Girafe_de_Rostchild.jpg', 'CC BY 2.0', 'https://creativecommons.org/licenses/by/2.0', 'saipal', 'Girafe de Rostchild.jpg', '2026-09-02'),
    ('Wikidata', 'Q2032704', 0, 'https://upload.wikimedia.org/wikipedia/commons/0/04/Saadani_National_Park_road.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=original', 'https://thumb.wikimedia.org/wikipedia/commons/thumb/0/04/Saadani_National_Park_road.jpg/1280px-Saadani_National_Park_road.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail', 7360, 4912, 'Wikimedia Commons', 'https://commons.wikimedia.org/wiki/File:Saadani_National_Park_road.jpg', 'CC BY-SA 4.0', 'https://creativecommons.org/licenses/by-sa/4.0', 'Rasheedhrasheed', 'Saadani National Park road.jpg', '2026-09-02'),
    ('Wikidata', 'Q1636810', 0, 'https://upload.wikimedia.org/wikipedia/commons/4/43/Sitatoenga.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=original', 'https://thumb.wikimedia.org/wikipedia/commons/thumb/4/43/Sitatoenga.jpg/1280px-Sitatoenga.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail', 2816, 2112, 'Wikimedia Commons', 'https://commons.wikimedia.org/wiki/File:Sitatoenga.jpg', 'CC BY-SA 3.0', 'https://creativecommons.org/licenses/by-sa/3.0', 'Kennyannydenny', 'Sitatoenga.jpg', '2026-09-02'),
    ('Wikidata', 'Q762107', 0, 'https://upload.wikimedia.org/wikipedia/commons/4/4b/Shaba_reserve_Kenya_mountains.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=original', 'https://upload.wikimedia.org/wikipedia/commons/4/4b/Shaba_reserve_Kenya_mountains.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail_unscaled', 800, 533, 'Wikimedia Commons', 'https://commons.wikimedia.org/wiki/File:Shaba_reserve_Kenya_mountains.jpg', 'CC BY 2.0', 'https://creativecommons.org/licenses/by/2.0', 'Marc Samsom', 'Shaba reserve Kenya mountains.jpg', '2026-09-02'),
    ('Wikidata', 'Q3524629', 0, 'https://upload.wikimedia.org/wikipedia/commons/c/cf/Thimlich_Ohinga_Cultural_Landscape-_Kenya.JPG?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=original', 'https://thumb.wikimedia.org/wikipedia/commons/thumb/c/cf/Thimlich_Ohinga_Cultural_Landscape-_Kenya.JPG/1280px-Thimlich_Ohinga_Cultural_Landscape-_Kenya.JPG?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail', 2592, 1944, 'Wikimedia Commons', 'https://commons.wikimedia.org/wiki/File:Thimlich_Ohinga_Cultural_Landscape-_Kenya.JPG', 'CC BY-SA 3.0', 'https://creativecommons.org/licenses/by-sa/3.0', 'Wycondi', 'Thimlich Ohinga Cultural Landscape- Kenya.JPG', '2026-09-02'),
    ('Wikidata', 'Q1368818', 0, 'https://upload.wikimedia.org/wikipedia/commons/a/a7/TsavoGate67.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=original', 'https://upload.wikimedia.org/wikipedia/commons/a/a7/TsavoGate67.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail_unscaled', 740, 470, 'Wikimedia Commons', 'https://commons.wikimedia.org/wiki/File:TsavoGate67.jpg', 'CC BY-SA 3.0', 'http://creativecommons.org/licenses/by-sa/3.0/', 'from en wikipedia', 'TsavoGate67.jpg', '2026-09-02'),
    ('Wikidata', 'Q1602738', 0, 'https://upload.wikimedia.org/wikipedia/commons/e/ee/TsavoDawn.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=original', 'https://upload.wikimedia.org/wikipedia/commons/e/ee/TsavoDawn.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail_unscaled', 510, 344, 'Wikimedia Commons', 'https://commons.wikimedia.org/wiki/File:TsavoDawn.jpg', 'Public domain', null, 'Andrew Wielochowski, aka User:Alw007', 'TsavoDawn.jpg', '2026-09-02'),
    ('Wikidata', 'Q3552272', 0, 'https://upload.wikimedia.org/wikipedia/commons/0/00/Urewe_Culture_Map.png?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=original', 'https://thumb.wikimedia.org/wikipedia/commons/thumb/0/00/Urewe_Culture_Map.png/1280px-Urewe_Culture_Map.png?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail', 1746, 1257, 'Wikimedia Commons', 'https://commons.wikimedia.org/wiki/File:Urewe_Culture_Map.png', 'CC BY-SA 4.0', 'https://creativecommons.org/licenses/by-sa/4.0', 'Yaldi5', 'Urewe Culture Map.png', '2026-09-02'),
    ('Wikidata', 'Q1107102', 0, 'https://upload.wikimedia.org/wikipedia/commons/2/2f/Watamu_Marine_Park.JPG?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=original', 'https://upload.wikimedia.org/wikipedia/commons/2/2f/Watamu_Marine_Park.JPG?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail_unscaled', 448, 336, 'Wikimedia Commons', 'https://commons.wikimedia.org/wiki/File:Watamu_Marine_Park.JPG', 'CC BY-SA 3.0', 'https://creativecommons.org/licenses/by-sa/3.0', 'Useslip', 'Watamu Marine Park.JPG', '2026-09-02')
),
matched_images as (
  select
    places.id as place_id,
    raw_place_images.sort_order,
    raw_place_images.image_url,
    raw_place_images.thumbnail_url,
    raw_place_images.width,
    raw_place_images.height,
    raw_place_images.source,
    raw_place_images.source_url,
    raw_place_images.licence,
    raw_place_images.licence_url,
    raw_place_images.attribution,
    raw_place_images.external_id,
    raw_place_images.last_verified_at::date
  from raw_place_images
  join public.places
    on places.source = raw_place_images.place_source
   and places.external_id = raw_place_images.place_external_id
)
insert into public.place_images (
  place_id,
  sort_order,
  image_url,
  thumbnail_url,
  width,
  height,
  source,
  source_url,
  licence,
  licence_url,
  attribution,
  external_id,
  last_verified_at
)
select
  place_id,
  sort_order,
  image_url,
  thumbnail_url,
  width,
  height,
  source,
  source_url,
  licence,
  licence_url,
  attribution,
  external_id,
  last_verified_at
from matched_images
on conflict (source, external_id) do update set
  place_id = excluded.place_id,
  sort_order = excluded.sort_order,
  image_url = excluded.image_url,
  thumbnail_url = excluded.thumbnail_url,
  width = excluded.width,
  height = excluded.height,
  source_url = excluded.source_url,
  licence = excluded.licence,
  licence_url = excluded.licence_url,
  attribution = excluded.attribution,
  last_verified_at = excluded.last_verified_at;

