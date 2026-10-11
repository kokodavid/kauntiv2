import importlib.util
import sys
import unittest
from pathlib import Path


def load_module():
    path = Path(__file__).parents[1] / 'copy_dev_place_to_prod.py'
    sys.path.insert(0, str(path.parent))
    spec = importlib.util.spec_from_file_location('copy_dev_place_to_prod', path)
    module = importlib.util.module_from_spec(spec)
    sys.modules[spec.name] = module
    spec.loader.exec_module(module)
    return module


tool = load_module()


class MatchingPlacesTest(unittest.TestCase):
    def test_matches_case_insensitively_after_trimming(self):
        rows = [{'id': 'one', 'name': ' Bisanadi National Reserve '}]
        self.assertEqual(tool.matching_places(rows, 'bisanadi national reserve', None), rows)

    def test_place_id_resolves_duplicate_name(self):
        rows = [
            {'id': 'one', 'name': 'Bisanadi National Reserve'},
            {'id': 'two', 'name': 'Bisanadi National Reserve'},
        ]
        self.assertEqual(tool.matching_places(rows, 'Bisanadi National Reserve', 'two'), [rows[1]])


if __name__ == '__main__':
    unittest.main()
