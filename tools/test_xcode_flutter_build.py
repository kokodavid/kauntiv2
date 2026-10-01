import base64
import json
from pathlib import Path
import tempfile
import unittest

from xcode_flutter_build import build_environment


class XcodeFlutterBuildTest(unittest.TestCase):
    def setUp(self):
        self.directory = tempfile.TemporaryDirectory()
        self.addCleanup(self.directory.cleanup)
        self.root = Path(self.directory.name)
        (self.root / "ios").mkdir()
        (self.root / "dart_defines").mkdir()

    def _environment(self, configuration):
        return {
            "CONFIGURATION": configuration,
            "SRCROOT": str(self.root / "ios"),
            "FLUTTER_TARGET": "lib/main.dart",
        }

    def test_dev_archive_sets_entry_point_and_all_defines(self):
        defines = {
            "SUPABASE_URL": "https://example.test",
            "SUPABASE_PUBLISHABLE_KEY": "public-key",
            "GOOGLE_WEB_CLIENT_ID": "web-client",
            "GOOGLE_IOS_CLIENT_ID": "ios-client",
            "JOURNEYS_ENABLED": True,
        }
        (self.root / "dart_defines/dev.json").write_text(json.dumps(defines))

        environment = build_environment(self._environment("Release-dev"))

        self.assertEqual(environment["FLUTTER_TARGET"], "lib/main_dev.dart")
        decoded = {
            base64.b64decode(item).decode("utf-8")
            for item in environment["DART_DEFINES"].split(",")
        }
        self.assertEqual(
            decoded,
            {f"{key}={value}" for key, value in defines.items() if key != "JOURNEYS_ENABLED"}
            | {"JOURNEYS_ENABLED=true"},
        )

    def test_missing_config_fails_instead_of_building_without_auth(self):
        with self.assertRaisesRegex(ValueError, "Missing .*dev.json"):
            build_environment(self._environment("Release-dev"))

    def test_runner_release_is_not_an_archive_flavor(self):
        with self.assertRaisesRegex(ValueError, "dev or prod scheme"):
            build_environment(self._environment("Release"))

    def test_default_debug_keeps_flutter_environment(self):
        environment = self._environment("Debug")
        self.assertEqual(build_environment(environment), environment)


if __name__ == "__main__":
    unittest.main()
