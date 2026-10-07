import importlib.util
import sys
import unittest
from pathlib import Path


def load_collector():
    path = Path(__file__).parents[1] / 'collect_wikidata_places.py'
    spec = importlib.util.spec_from_file_location('collect_wikidata_places', path)
    module = importlib.util.module_from_spec(spec)
    sys.modules[spec.name] = module
    spec.loader.exec_module(module)
    return module


collector = load_collector()


def binding(qid, name, point, kind='Waterfall', description=None):
    row = {
        'item': {'value': f'http://www.wikidata.org/entity/{qid}'},
        'itemLabel': {'value': name},
        'coord': {'value': point},
        'kind': {'value': kind},
    }
    if description:
        row['description'] = {'value': description}
    return row


class WikidataCollectorTest(unittest.TestCase):
    def test_parse_point_returns_latitude_then_longitude(self):
        self.assertEqual(collector.parse_point('Point(36.8219 -1.2921)'), (-1.2921, 36.8219))

    def test_parse_point_rejects_invalid_wkt_and_ranges(self):
        self.assertIsNone(collector.parse_point('36.8219,-1.2921'))
        self.assertIsNone(collector.parse_point('Point(200 100)'))

    def test_places_skip_invalid_rows_and_dedupe_qids(self):
        places = collector.places_from_bindings([
            binding('Q1', 'A waterfall', 'Point(36.8219 -1.2921)', description='A test record.'),
            binding('Q1', 'A waterfall', 'Point(36.8219 -1.2921)', kind='Park'),
            binding('Q2', 'Broken', 'not a point'),
            {'item': {'value': 'http://www.wikidata.org/entity/Q3'}},
        ])

        self.assertEqual(len(places), 1)
        self.assertEqual(places[0].key, 'Q1')
        self.assertEqual(places[0].kind, 'Waterfall')
        self.assertEqual(places[0].payload()['licence'], 'CC0')
        self.assertEqual(places[0].payload()['images'], [])

    def test_query_is_bounded_and_kenya_only(self):
        query = collector.endpoint_query(25)
        self.assertIn('wd:Q114', query)
        self.assertIn('LIMIT 25', query)
        self.assertIn('wd:Q355304', query)


if __name__ == '__main__':
    unittest.main()
