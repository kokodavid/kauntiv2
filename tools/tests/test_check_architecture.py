"""Tests for tools/check_architecture.py. Run: python3 -m unittest discover tools/tests"""

import json
import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import check_architecture as ca  # noqa: E402


class Repo:
    def __init__(self):
        self._tmp = tempfile.TemporaryDirectory()
        self.root = Path(self._tmp.name)
        (self.root / "tools").mkdir()

    def write(self, rel, text=""):
        p = self.root / rel
        p.parent.mkdir(parents=True, exist_ok=True)
        p.write_text(text, encoding="utf-8")

    def rules(self):
        return sorted((v.rule, v.path) for v in ca.scan(self.root))

    def run(self, *args):
        return ca.main(["--root", str(self.root), *args])

    def close(self):
        self._tmp.cleanup()


class ArchitectureTests(unittest.TestCase):
    def setUp(self):
        self.repo = Repo()

    def tearDown(self):
        self.repo.close()

    def test_clean_feature_passes(self):
        r = self.repo
        r.write("lib/main_dev.dart", "import 'src/app/app.dart';\n")
        r.write("lib/src/app/app.dart", "import '../features/map/presentation/map_screen.dart';\n")
        r.write("lib/src/features/map/domain/county.dart", "import 'package:meta/meta.dart';\n")
        r.write("lib/src/features/map/data/map_repository.dart",
                "import 'package:supabase_flutter/supabase_flutter.dart';\nimport '../domain/county.dart';\n")
        r.write("lib/src/features/map/application/map_controller.dart",
                "import 'package:riverpod_annotation/riverpod_annotation.dart';\n"
                "import '../data/map_repository.dart';\npart 'map_controller.g.dart';\n"
                "@riverpod\nclass MapController extends _$MapController {}\n")
        r.write("lib/src/features/map/application/map_controller.g.dart",
                "final mapControllerProvider = NotifierProvider(() => 1);\n")
        r.write("lib/src/features/map/presentation/map_screen.dart",
                "import 'package:flutter/material.dart';\nimport '../application/map_controller.dart';\n"
                "class _S extends State<X> { void f() { setState(() {}); } }\n"
                "void g(WidgetRef ref) { ref.watch(mapControllerProvider); ref.watch(countyProvider(3)); }\n")
        r.write("lib/src/core/widgets/app_card.dart", "import 'package:flutter/material.dart';\n")
        self.assertEqual(r.rules(), [])

    def test_layout_violations(self):
        r = self.repo
        r.write("lib/src/screens/home.dart")
        r.write("lib/src/features/map/map_screen.dart")
        r.write("lib/src/features/map/widgets/pin.dart")
        r.write("lib/helpers.dart")
        self.assertEqual({p for rule, p in r.rules() if rule == "layout"}, {
            "lib/src/screens/home.dart", "lib/src/features/map/map_screen.dart",
            "lib/src/features/map/widgets/pin.dart", "lib/helpers.dart"})

    def test_presentation_cannot_import_data(self):
        r = self.repo
        r.write("lib/src/features/map/data/repo.dart")
        r.write("lib/src/features/map/presentation/s.dart", "import '../data/repo.dart';\n")
        self.assertIn(("layer-import", "lib/src/features/map/presentation/s.dart"), r.rules())

    def test_package_imports_are_resolved(self):
        r = self.repo
        r.write("lib/src/features/map/presentation/s.dart",
                "import 'package:kaunti47_v2/src/features/map/data/repo.dart';\n")
        r.write("lib/src/features/map/data/repo.dart")
        self.assertIn(("layer-import", "lib/src/features/map/presentation/s.dart"), r.rules())

    def test_cross_feature_only_domain_and_application(self):
        r = self.repo
        r.write("lib/src/features/badges/domain/badge.dart")
        r.write("lib/src/features/badges/application/c.dart")
        r.write("lib/src/features/badges/presentation/badge_screen.dart")
        r.write("lib/src/features/map/presentation/s.dart",
                "import '../../badges/domain/badge.dart';\n"
                "import '../../badges/application/c.dart';\n"
                "import '../../badges/presentation/badge_screen.dart';\n")
        found = [x for x in r.rules() if x[0] == "layer-import"]
        self.assertEqual(found, [("layer-import", "lib/src/features/map/presentation/s.dart")])

    def test_core_cannot_import_features(self):
        r = self.repo
        r.write("lib/src/features/map/domain/c.dart")
        r.write("lib/src/core/widgets/w.dart", "import '../../features/map/domain/c.dart';\n")
        self.assertIn(("layer-import", "lib/src/core/widgets/w.dart"), r.rules())

    def test_domain_purity(self):
        r = self.repo
        r.write("lib/src/features/map/domain/c.dart", "import 'package:flutter/material.dart';\n")
        self.assertIn(("domain-purity", "lib/src/features/map/domain/c.dart"), r.rules())

    def test_io_only_in_data_or_core(self):
        r = self.repo
        r.write("lib/src/features/map/application/c.dart", "import 'package:supabase_flutter/supabase_flutter.dart';\n")
        r.write("lib/src/features/map/presentation/s.dart", "import 'package:shared_preferences/shared_preferences.dart';\n")
        r.write("lib/src/core/supabase/client.dart", "import 'package:supabase_flutter/supabase_flutter.dart';\n")
        rules = r.rules()
        self.assertIn(("io-outside-data", "lib/src/features/map/application/c.dart"), rules)
        self.assertIn(("io-outside-data", "lib/src/features/map/presentation/s.dart"), rules)
        self.assertNotIn(("io-outside-data", "lib/src/core/supabase/client.dart"), rules)

    def test_application_no_widgets(self):
        r = self.repo
        r.write("lib/src/features/map/application/a.dart", "import 'package:flutter/foundation.dart';\n")
        r.write("lib/src/features/map/application/b.dart", "import 'package:flutter/material.dart';\n")
        self.assertEqual([x for x in r.rules() if x[0] == "application-flutter"],
                         [("application-flutter", "lib/src/features/map/application/b.dart")])

    def test_banned_state_and_packages(self):
        r = self.repo
        r.write("lib/src/features/map/application/c.dart",
                "import 'package:provider/provider.dart';\nclass C extends ChangeNotifier {}\n"
                "// ValueNotifier in a comment is fine\n")
        rules = r.rules()
        self.assertIn(("banned-package", "lib/src/features/map/application/c.dart"), rules)
        self.assertEqual(rules.count(("banned-state", "lib/src/features/map/application/c.dart")), 1)

    def test_setstate_outside_ui(self):
        r = self.repo
        r.write("lib/src/app/app.dart", "void f() { setState(() {}); setState(() {}); }\n")
        self.assertEqual(r.rules().count(("setstate-outside-ui", "lib/src/app/app.dart")), 2)

    def test_manual_provider_and_location(self):
        r = self.repo
        r.write("lib/src/features/map/application/p.dart",
                "final a = Provider((ref) => 1);\nfinal b = FutureProvider.autoDispose<int>((ref) async => 1);\n"
                "void t() { ProviderScope(child: x); ProviderContainer(); }\n")
        r.write("lib/src/features/map/data/r.dart", "@riverpod\nint r(Ref ref) => 1;\n")
        rules = r.rules()
        self.assertEqual(rules.count(("manual-provider", "lib/src/features/map/application/p.dart")), 2)
        self.assertIn(("provider-location", "lib/src/features/map/data/r.dart"), rules)

    def test_router_may_declare_its_provider(self):
        r = self.repo
        r.write("lib/src/app/router.dart", "@Riverpod(keepAlive: true)\nint appRouter(Ref ref) => 1;\n")
        r.write("lib/src/app/other.dart", "@riverpod\nint other(Ref ref) => 1;\n")
        rules = r.rules()
        self.assertNotIn(("provider-location", "lib/src/app/router.dart"), rules)
        self.assertIn(("provider-location", "lib/src/app/other.dart"), rules)

    def test_supabase_instance_only_in_core(self):
        r = self.repo
        r.write("lib/src/features/map/data/r.dart", "final c = Supabase.instance.client;\n")
        self.assertIn(("supabase-instance", "lib/src/features/map/data/r.dart"), r.rules())

    def test_file_length(self):
        r = self.repo
        r.write("lib/src/app/app.dart", "\n" * (ca.MAX_FILE_LINES + 1))
        r.write("lib/src/app/ok.dart", "\n" * ca.MAX_FILE_LINES)
        self.assertEqual([x for x in r.rules() if x[0] == "file-length"],
                         [("file-length", "lib/src/app/app.dart")])

    def test_baseline_blocks_new_and_stale(self):
        r = self.repo
        r.write("lib/src/app/app.dart", "void f() { setState(() {}); }\n")
        self.assertEqual(r.run(), 1)                    # new debt
        self.assertEqual(r.run("--update-baseline"), 0)
        self.assertEqual(r.run(), 0)                    # baselined
        r.write("lib/src/app/app.dart", "void f() { setState(() {}); setState(() {}); }\n")
        self.assertEqual(r.run(), 1)                    # grew within a file
        r.write("lib/src/app/app.dart", "void f() {}\n")
        self.assertEqual(r.run(), 1)                    # paid down but baseline stale
        self.assertEqual(r.run("--update-baseline"), 0)
        self.assertEqual(r.run(), 0)

    def test_no_grow_from(self):
        r = self.repo
        old = r.root / "old.json"
        old.write_text(json.dumps({"violations": {"layout": {"lib/a.dart": 1}}}))
        (r.root / "tools/architecture_baseline.json").write_text(
            json.dumps({"violations": {"layout": {"lib/a.dart": 1, "lib/b.dart": 1}}}))
        self.assertEqual(r.run("--no-grow-from", str(old)), 1)
        (r.root / "tools/architecture_baseline.json").write_text(json.dumps({"violations": {}}))
        self.assertEqual(r.run("--no-grow-from", str(old)), 0)
        self.assertEqual(r.run("--no-grow-from", str(r.root / "missing.json")), 0)


if __name__ == "__main__":
    unittest.main()
