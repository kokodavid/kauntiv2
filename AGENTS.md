# Agent rules (Claude, Codex, Qwen, any AI or human contributor)

Read this before you touch code. `docs/architecture.md` is the source of
truth for how to build in Kaunti47 v2: structure, layers, state management,
routing, tests, and CI expectations. This file is the working checklist that
points agents back to that guide and adds migration-specific operating rules.

## Project direction

Kaunti47 v2 is a clean Flutter rebuild of Kaunti47 v1, not a wholesale copy
of the old project. Keep v2 intentionally small and structured: port behavior
from v1 in focused slices, then re-home it into the v2 architecture.

Reference locations:

- v2 project: `/Users/davidmochoge/Projects/Kaunti47 v2`
- v1 reference project: `/Users/davidmochoge/Projects/kaunti47`
- v1 Supabase migrations: `/Users/davidmochoge/Projects/kaunti47/supabase/migrations`
- v2 architecture source of truth: `docs/architecture.md`
- v2 migration tracker: `docs/port-tracker.md`

Use v1 and the design source as product truth. Do not invent behavior to fill
gaps. If the v1 behavior is unclear, inspect the v1 feature, its repositories,
and the related Supabase migrations before deciding.

## Non-negotiables

1. **Riverpod only.** Declare state with `@riverpod` codegen, in
   `application/` (infrastructure providers go in `core/`). Never use
   `ChangeNotifier`, `ValueNotifier`, `StateNotifier`, `StateProvider`,
   `provider`, `bloc`, `get` or hooks. `setState` is for ephemeral UI state
   inside `presentation/` only.
2. **Feature structure:** `lib/src/features/<feature>/{domain,data,application,presentation}/`.
   Shared code goes in `lib/src/core/`, and app wiring in `lib/src/app/`.
   Nothing else goes under `lib/`.
3. **Layer boundaries:**
   - Presentation never imports data.
   - Domain is plain Dart.
   - I/O packages are used only in `data/` (or `core/` infrastructure).
   - Across features, import only `domain/` and `application/`.
4. **Files stay at or under 300 lines.** Split rather than grow.
5. **One feature per branch/PR.** Codex work uses `codex/<name>` by default
   unless the user asks for a different branch. Unrelated changes stay out of
   the diff.
6. **Never grow `tools/architecture_baseline.json`.** If you remove debt,
   regenerate it in the same PR.
7. **Update `docs/port-tracker.md`** in every PR that ports or changes a
   feature.
8. **Don't invent product behavior.** v1 (`kokodavid/kaunti47`) and the
   design canvas are the source of truth. When something is ambiguous, stop
   and ask.
9. **Avoid screen flashes.** Do not briefly show the wrong screen, mock data,
   stale account data, empty/default content, or a previous state while auth,
   onboarding, permissions, or Supabase data is being resolved. Use intentional
   loading states and report what was visually verified.

## Command discipline

Do not run Flutter or Dart commands during routine code updates unless the user
explicitly asks for them. This includes `flutter analyze`, `flutter test`,
`flutter build`, `flutter run`, `dart format`, `dart analyze`, and
`build_runner`. Prefer focused inspection and the lightweight architecture
checker:

```bash
python3 tools/check_architecture.py
```

If you do run or skip verification, state that clearly in your final update.
Avoid broad, high-output commands. Use narrow `rg`, small `sed` ranges, and
file-scoped diffs.

## Before you open a PR

When preparing a formal PR, these are the full checks expected by CI:

```bash
dart format lib test
dart run build_runner build --delete-conflicting-outputs
flutter analyze --fatal-infos
dart run custom_lint
python3 tools/check_architecture.py
flutter test
```

Only run them when the user asks or when the task explicitly calls for PR-ready
verification. If you couldn't run something, say so explicitly in the PR
description. Don't claim it passed.

## Porting from v1

- Port behavior, not files. Re-home each piece into the correct layer
  instead of copying v1's structure.
- v1 already follows domain/data/application/presentation for most
  features, but its screens routinely run past 1,000 lines. Split them
  while porting.
- Supabase migrations from v1 live in
  `/Users/davidmochoge/Projects/kaunti47/supabase/migrations`. Use them to
  understand schema, RPCs, return shapes, and environment expectations.
- New schema changes in v2 go in new, timestamped migration files. Never edit
  an applied migration.
- Keep v2 project files clean. Do not copy v1 folders wholesale or bring over
  generated artifacts that are unrelated to the Flutter app.
- Update `docs/port-tracker.md` every time a feature or meaningful sub-feature
  moves from v1 to v2.
