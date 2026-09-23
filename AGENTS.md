# Agent rules (Claude, Codex, Qwen, any AI or human contributor)

Read this before you touch code. The full rules are in
`docs/architecture.md`, and CI enforces them.

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
5. **One feature per branch/PR,** named `feature/<name>`, `fix/<name>`,
   `refactor/<name>` or `setup/<name>`. Unrelated changes stay out of the
   diff.
6. **Never grow `tools/architecture_baseline.json`.** If you remove debt,
   regenerate it in the same PR.
7. **Update `docs/port-tracker.md`** in every PR that ports or changes a
   feature.
8. **Don't invent product behavior.** v1 (`kokodavid/kaunti47`) and the
   design canvas are the source of truth. When something is ambiguous, stop
   and ask.

## Before you open a PR

Run these and make sure every one passes:

```bash
dart format lib test
dart run build_runner build --delete-conflicting-outputs
flutter analyze --fatal-infos
dart run custom_lint
python3 tools/check_architecture.py
flutter test
```

If you couldn't run something, say so explicitly in the PR description.
Don't claim it passed.

## Porting from v1

- Port behavior, not files. Re-home each piece into the correct layer
  instead of copying v1's structure.
- v1 already follows domain/data/application/presentation for most
  features, but its screens routinely run past 1,000 lines. Split them
  while porting.
- Supabase migrations are already at v1 parity in `supabase/migrations/`.
  New schema changes go in new, timestamped migration files. Never edit an
  applied migration.
