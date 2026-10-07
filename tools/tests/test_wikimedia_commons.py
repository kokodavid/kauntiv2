import importlib.util
import sys
import unittest
from pathlib import Path


def load_commons():
    path = Path(__file__).parents[1] / 'wikimedia_commons.py'
    spec = importlib.util.spec_from_file_location('wikimedia_commons', path)
    module = importlib.util.module_from_spec(spec)
    sys.modules[spec.name] = module
    spec.loader.exec_module(module)
    return module


commons = load_commons()


class WikimediaCommonsTest(unittest.TestCase):
    def test_extracts_commons_file_title_only(self):
        self.assertEqual(
            commons.file_title('http://commons.wikimedia.org/wiki/Special:FilePath/A%20waterfall.jpg'),
            'File:A waterfall.jpg',
        )
        self.assertIsNone(commons.file_title('https://example.com/wiki/Special:FilePath/nope.jpg'))

    def test_plain_text_removes_markup(self):
        self.assertEqual(commons.text('<a href="#">Jane</a> &amp; <b>Team</b>'), 'Jane & Team')

    def test_limits_licences_to_reusable_commons_terms(self):
        self.assertTrue(commons.is_allowed_licence('CC BY-SA 4.0'))
        self.assertTrue(commons.is_allowed_licence('Public domain'))
        self.assertFalse(commons.is_allowed_licence('All rights reserved'))


if __name__ == '__main__':
    unittest.main()
