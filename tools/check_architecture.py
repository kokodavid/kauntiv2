#!/usr/bin/env python3
"""Kaunti47 architecture guard.

Enforces the rules in docs/architecture.md mechanically so they don't depend
on anyone remembering them. Runs in CI on every pull request and locally via:

    python3 tools/check_architecture.py                 # check
    python3 tools/check_architecture.py --update-baseline
    python3 tools/check_architecture.py --no-grow-from <old_baseline.json>

Pure standard library on purpose: it runs anywhere Python 3.9+ exists (CI
runners, macOS) without pub get or a Flutter SDK.

Baseline: tools/architecture_baseline.json records violations that existed
when the guard was introduced, as {rule: {path: count}}. The check fails when
a file has MORE violations of a rule than its baseline allows (new debt) and
also when it has FEWER (the baseline must be tightened in the same PR, so
debt only ever goes down). CI additionally refuses any PR that grows the
baseline compared with main.
"""

from __future__ import annotations

import argparse
import json
import os
import re
import sys
from collections import defaultdict
from dataclasses import dataclass
from pathlib import Path

PACKAGE_NAME = "kaunti47_v2"
MAX_FILE_LINES = 300

LAYERS = ("domain", "data", "application", "presentation")
TOP_LEVEL_DIRS = ("app", "core", "features")

# Files that are allowed past MAX_FILE_LINES. Every entry needs a reason and
# is owned by CODEOWNERS (this file). Pure generated/static data only.
LONG_FILE_EXEMPTIONS = {
    "lib/src/core/counties/county_paths.dart": "static SVG geometry for 47 counties",
    "lib/src/counties/county_paths.dart": "static SVG geometry (pre-move location)",
    "lib/src/core/counties/county_boundaries.dart": "generated county polygons for GPS-to-county lookup (from the counties seed)",
}

# The app router (architecture §5): the one @riverpod provider allowed in
# lib/src/app, since it wires every feature's screens together.
ROUTER_FILE = "lib/src/app/router.dart"

GENERATED_SUFFIXES = (".g.dart", ".freezed.dart", ".gr.dart", ".mocks.dart")

# Which layers of the SAME feature each layer may import.
SAME_FEATURE_ALLOWED = {
    "domain": {"domain"},
    "data": {"domain", "data"},
    "application": {"domain", "data", "application"},
    "presentation": {"domain", "application", "presentation"},
}
# Layers of ANOTHER feature that may be imported at all (intersected with
# SAME_FEATURE_ALLOWED). A feature never reaches into another's data layer
# or screens; navigation goes through lib/src/app/router.
CROSS_FEATURE_PUBLIC = {"domain", "application"}

# Packages that do I/O. Only data layers (and core infrastructure) touch them.
IO_PACKAGES = {
    "supabase", "supabase_flutter", "gotrue", "postgrest",
    "drift", "drift_flutter", "sqlite3", "sqflite",
    "http", "dio", "shared_preferences", "flutter_secure_storage",
    "native_geofence", "geolocator", "permission_handler",
    "google_sign_in", "sign_in_with_apple", "image_picker",
    "url_launcher", "path_provider", "connectivity_plus",
}
# State-management packages that compete with Riverpod. Banned everywhere.
BANNED_PACKAGES = {
    "provider", "get", "getx", "bloc", "flutter_bloc", "mobx",
    "flutter_mobx", "hooks_riverpod", "flutter_hooks", "states_rebuilder",
}
# The only packages plain-Dart domain code may import.
DOMAIN_ALLOWED_PACKAGES = {
    PACKAGE_NAME, "meta", "collection", "equatable",
    "freezed_annotation", "json_annotation",
}
# Flutter libraries the application layer may import (no widgets there).
APPLICATION_ALLOWED_FLUTTER = {"package:flutter/foundation.dart"}

BANNED_STATE_RE = re.compile(
    r"\b(ChangeNotifier|ValueNotifier|StateNotifier|StateNotifierProvider|"
    r"StateProvider|ChangeNotifierProvider|InheritedWidget|InheritedNotifier|"
    r"InheritedModel)\b"
)
SET_STATE_RE = re.compile(r"\bsetState\s*\(")
RIVERPOD_ANNOTATION_RE = re.compile(r"@(riverpod|Riverpod\s*\()")
# Hand-written provider constructors: Provider(...), FutureProvider<...>(...),
# NotifierProvider.family(...). Codegen (@riverpod) is the only allowed form.
MANUAL_PROVIDER_RE = re.compile(
    r"(?<![\w.])(?:[A-Z]\w*)?Provider(?:\s*\.\s*(?:family|autoDispose))*\s*[<(]"
)
SUPABASE_INSTANCE_RE = re.compile(r"\bSupabase\s*\.\s*instance\b")
DIRECTIVE_RE = re.compile(r"""^\s*(?:import|export)\s+['"]([^'"]+)['"]""", re.M)

RULE_DOCS = {
    "layout": "File is outside the allowed structure (lib/main*.dart, lib/src/{app,core,features/<f>/<layer>}).",
    "layer-import": "Import crosses a forbidden layer/feature boundary.",
    "domain-purity": "Domain code imports a package other than plain-Dart helpers.",
    "io-outside-data": "I/O package used outside a data layer or core infrastructure.",
    "application-flutter": "Application layer imports Flutter UI libraries (only foundation.dart allowed).",
    "banned-package": "Competing state-management package imported (Riverpod only).",
    "banned-state": "ChangeNotifier/ValueNotifier/StateNotifier/StateProvider/Inherited* used (Riverpod only).",
    "setstate-outside-ui": "setState used outside presentation/ or core/widgets/.",
    "manual-provider": "Hand-written provider constructor; declare providers with @riverpod codegen.",
    "provider-location": "@riverpod provider declared outside application/, core/ or app/router.dart.",
    "supabase-instance": "Supabase.instance used outside core/; read supabaseClientProvider instead.",
    "file-length": f"File exceeds {MAX_FILE_LINES} lines; split it.",
}


@dataclass(frozen=True)
class Zone:
    kind: str  # entry | app | core | feature | unknown
    feature: str | None = None
    layer: str | None = None
    core_sub: str | None = None  # first dir under core/, e.g. "widgets", "domain"


@dataclass(frozen=True)
class Violation:
    rule: str
    path: str
    detail: str


def zone_of(rel: str) -> Zone:
    """rel is a posix path relative to the repo root, starting with lib/."""
    parts = rel.split("/")[1:]  # drop "lib"
    if len(parts) == 1:
        name = parts[0]
        if re.fullmatch(r"main(_\w+)?\.dart", name):
            return Zone("entry")
        return Zone("unknown")
    if parts[0] != "src" or len(parts) < 3:
        return Zone("unknown")
    top = parts[1]
    if top == "app":
        return Zone("app")
    if top == "core":
        return Zone("core", core_sub=parts[2] if len(parts) > 3 else None)
    if top == "features":
        if len(parts) < 5 or parts[3] not in LAYERS:
            return Zone("unknown")
        return Zone("feature", feature=parts[2], layer=parts[3])
    return Zone("unknown")


def strip_comments(src: str) -> str:
    src = re.sub(r"/\*.*?\*/", "", src, flags=re.S)
    return re.sub(r"//[^\n]*", "", src)


def resolve(directive: str, file_rel: str) -> tuple[str, str]:
    """Return ("lib", rel_path) for in-project targets, ("pkg", name) for
    other packages, ("dart", lib) for SDK libraries."""
    if directive.startswith("dart:"):
        return ("dart", directive)
    if directive.startswith("package:"):
        name, _, rest = directive[len("package:"):].partition("/")
        if name == PACKAGE_NAME:
            return ("lib", "lib/" + rest)
        return ("pkg", name)
    base = os.path.dirname(file_rel)
    return ("lib", os.path.normpath(os.path.join(base, directive)).replace(os.sep, "/"))


def import_allowed(src: Zone, tgt: Zone) -> bool:
    if tgt.kind == "unknown" or src.kind == "unknown":
        return True  # already reported as a layout violation
    if src.kind == "app":
        return True
    if src.kind == "entry":
        return tgt.kind in ("entry", "app", "core")
    if src.kind == "core":
        if tgt.kind != "core":
            return False
        if src.core_sub == "domain":
            return tgt.core_sub == "domain"
        return True
    # feature
    if tgt.kind == "app" or tgt.kind == "entry":
        return False
    if tgt.kind == "core":
        if src.layer == "domain":
            return tgt.core_sub == "domain"
        return True
    allowed = SAME_FEATURE_ALLOWED[src.layer]
    if tgt.feature == src.feature:
        return tgt.layer in allowed
    return tgt.layer in (allowed & CROSS_FEATURE_PUBLIC)


def check_file(root: Path, path: Path) -> list[Violation]:
    rel = path.relative_to(root).as_posix()
    raw = path.read_text(encoding="utf-8")
    code = strip_comments(raw)
    z = zone_of(rel)
    out: list[Violation] = []

    def add(rule: str, detail: str) -> None:
        out.append(Violation(rule, rel, detail))

    if z.kind == "unknown":
        add("layout", "move under lib/src/app, lib/src/core or lib/src/features/<feature>/<layer>/")

    is_domain = (z.kind == "feature" and z.layer == "domain") or (
        z.kind == "core" and z.core_sub == "domain")
    is_data = z.kind == "feature" and z.layer == "data"
    is_core_infra = z.kind == "core" and z.core_sub != "domain"
    is_application = z.kind == "feature" and z.layer == "application"
    is_ui = (z.kind == "feature" and z.layer == "presentation") or (
        z.kind == "core" and z.core_sub == "widgets")

    for directive in DIRECTIVE_RE.findall(code):
        kind, target = resolve(directive, rel)
        if kind == "lib":
            tz = zone_of(target)
            if not import_allowed(z, tz):
                add("layer-import", f"{directive}")
        elif kind == "pkg":
            if target in BANNED_PACKAGES:
                add("banned-package", directive)
            if is_domain and target not in DOMAIN_ALLOWED_PACKAGES:
                add("domain-purity", directive)
            elif target in IO_PACKAGES and not (is_data or is_core_infra or z.kind == "app"):
                add("io-outside-data", directive)
            if is_application and target == "flutter" and directive not in APPLICATION_ALLOWED_FLUTTER:
                add("application-flutter", directive)

    for m in BANNED_STATE_RE.finditer(code):
        add("banned-state", m.group(1))
    if not is_ui:
        for _ in SET_STATE_RE.finditer(code):
            add("setstate-outside-ui", "setState(")
    for _ in MANUAL_PROVIDER_RE.finditer(code):
        add("manual-provider", "hand-written provider")
    if RIVERPOD_ANNOTATION_RE.search(code) and not (
            is_application or z.kind == "core" or rel == ROUTER_FILE):
        add("provider-location", "@riverpod")
    if SUPABASE_INSTANCE_RE.search(code) and z.kind != "core":
        add("supabase-instance", "Supabase.instance")

    lines = raw.count("\n") + (0 if raw.endswith("\n") else 1)
    if lines > MAX_FILE_LINES and rel not in LONG_FILE_EXEMPTIONS:
        add("file-length", f"{lines} lines")
    return out


def scan(root: Path) -> list[Violation]:
    lib = root / "lib"
    violations: list[Violation] = []
    for path in sorted(lib.rglob("*.dart")):
        if path.name.endswith(GENERATED_SUFFIXES):
            continue
        violations.extend(check_file(root, path))
    return violations


def tally(violations: list[Violation]) -> dict[str, dict[str, int]]:
    counts: dict[str, dict[str, int]] = defaultdict(lambda: defaultdict(int))
    for v in violations:
        counts[v.rule][v.path] += 1
    return {r: dict(sorted(p.items())) for r, p in sorted(counts.items())}


def load_json(path: Path) -> dict[str, dict[str, int]]:
    if not path.exists():
        return {}
    data = json.loads(path.read_text(encoding="utf-8"))
    return data.get("violations", {})


def write_baseline(path: Path, counts: dict[str, dict[str, int]]) -> None:
    payload = {
        "_comment": "Pre-existing architecture debt. May only shrink. "
                    "Regenerate with: python3 tools/check_architecture.py --update-baseline",
        "violations": counts,
    }
    path.write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")


def compare(current, baseline):
    """Return (new_debt, stale) lists of (rule, path, have, allowed)."""
    new, stale = [], []
    keys = {(r, p) for r in current for p in current[r]} | {
        (r, p) for r in baseline for p in baseline[r]}
    for rule, path in sorted(keys):
        have = current.get(rule, {}).get(path, 0)
        allowed = baseline.get(rule, {}).get(path, 0)
        if have > allowed:
            new.append((rule, path, have, allowed))
        elif have < allowed:
            stale.append((rule, path, have, allowed))
    return new, stale


def grew(old, new) -> list[tuple[str, str, int, int]]:
    out = []
    for rule, paths in new.items():
        for path, n in paths.items():
            before = old.get(rule, {}).get(path, 0)
            if n > before:
                out.append((rule, path, n, before))
    return out


def main(argv: list[str] | None = None) -> int:
    ap = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    ap.add_argument("--root", default=str(Path(__file__).resolve().parent.parent))
    ap.add_argument("--baseline", default=None)
    ap.add_argument("--update-baseline", action="store_true")
    ap.add_argument("--no-grow-from", metavar="OLD_BASELINE",
                    help="fail if the committed baseline has more debt than OLD_BASELINE")
    args = ap.parse_args(argv)

    root = Path(args.root).resolve()
    baseline_path = Path(args.baseline) if args.baseline else root / "tools" / "architecture_baseline.json"

    if args.no_grow_from:
        old_path = Path(args.no_grow_from)
        if not old_path.exists() or old_path.stat().st_size == 0:
            print("No baseline on the base branch yet; skipping growth check.")
            return 0
        growth = grew(load_json(old_path), load_json(baseline_path))
        if growth:
            print("✗ architecture_baseline.json GREW compared with the base branch.")
            print("  Fix the new violations instead of adding them to the baseline:")
            for rule, path, n, before in growth:
                print(f"  - [{rule}] {path}: {before} -> {n}")
            return 1
        print("✓ Architecture baseline did not grow.")
        return 0

    violations = scan(root)
    current = tally(violations)

    if args.update_baseline:
        write_baseline(baseline_path, current)
        total = sum(sum(p.values()) for p in current.values())
        print(f"Wrote {baseline_path.relative_to(root)} ({total} recorded violations).")
        return 0

    baseline = load_json(baseline_path)
    new, stale = compare(current, baseline)
    by_key = defaultdict(list)
    for v in violations:
        by_key[(v.rule, v.path)].append(v.detail)

    if new:
        print("✗ New architecture violations (see docs/architecture.md):\n")
        for rule, path, have, allowed in new:
            print(f"  [{rule}] {path}  ({have} found, {allowed} allowed)")
            print(f"      {RULE_DOCS[rule]}")
            for d in sorted(set(by_key[(rule, path)]))[:5]:
                print(f"      · {d}")
        print()
    if stale:
        print("✗ Baseline is out of date — debt was paid down (nice). Tighten it in this PR:")
        print("    python3 tools/check_architecture.py --update-baseline\n")
        for rule, path, have, allowed in stale:
            print(f"  [{rule}] {path}  (baseline {allowed}, now {have})")
        print()
    if new or stale:
        return 1

    remaining = sum(sum(p.values()) for p in baseline.values())
    msg = f"{remaining} baselined violation(s) left to burn down" if remaining else "no baselined debt"
    print(f"✓ Architecture check passed ({msg}).")
    return 0


if __name__ == "__main__":
    sys.exit(main())
