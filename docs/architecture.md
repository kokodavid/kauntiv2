# Architecture

These are the rules for Kaunti47 v2. Most are enforced mechanically, by
`tools/check_architecture.py`, `flutter analyze --fatal-infos` and
`riverpod_lint`. CI blocks a merge on any of them. The rest are covered by
review (see `docs/code-review.md`).

Why this exists: v1 grew to about 40k lines with no enforced structure. Big
files, state spread across widgets, and features reaching into each other
made it impossible to track or debug. v2 makes those failure modes fail CI
instead.

## 1. Folder structure

```
lib/
  main.dart, main_dev.dart, main_prod.dart   entrypoints only
  src/
    app/        app.dart (MaterialApp.router), router.dart, bootstrap.dart
    core/       shared, feature-agnostic code
      config/     AppConfig, AppEnvironment
      design/     colors, spacing, radii, text styles, theme
      widgets/    reusable UI (AppButton, AppCountyShape, ...)
      counties/   county geometry/data shared by several features
      domain/     plain-Dart models shared by several features
      services/   logger, supabase client provider, platform infra
    features/
      <feature>/
        domain/        models and value types (plain Dart)
        data/          repositories and data sources (all I/O)
        application/   @riverpod providers and notifiers (all state)
        presentation/  screens and widgets (UI only)
```

- Nothing else is allowed under `lib/` (checker rule `layout`). There are no
  `screens/`, `widgets/`, `services/` or `utils/` folders at the top level.
- A feature is a user-facing capability, such as `auth`, `onboarding`,
  `map_home`, `detection`, `discover`, `badges`, `profile`, `ranks`,
  `quests` or `friends`. Folder names use snake_case.
- A feature only has the layers it needs. Don't create empty folders.
- If two or more features need something, it goes in `core/`. Nothing
  moves to `core/` "just in case".

## 2. Layer rules (checker: `layer-import`, `domain-purity`, `io-outside-data`, `application-flutter`)

| Layer | May import (same feature) | May use packages |
|---|---|---|
| `domain` | `domain` | `dart:*`, `meta`, `collection`, `equatable`, `freezed_annotation`, `json_annotation`. No Flutter. |
| `data` | `domain`, `data` | I/O packages (Supabase, drift, http, prefs, geofence, permissions, sign-in SDKs, ...) |
| `application` | `domain`, `data`, `application` | Riverpod, `flutter/foundation.dart` only (no widgets) |
| `presentation` | `domain`, `application`, `presentation` | Flutter UI. **Never `data`.** |

- **Across features:** only another feature's `domain` and `application`
  may be imported. A feature never imports another feature's `data` or
  `presentation`. Navigation between features goes through
  `lib/src/app/router.dart`.
- **`core/`** never imports `app/` or `features/`. `core/domain/` follows
  the domain rules.
- **`app/`** may import anything. It's where the app is wired together.

## 3. State management: Riverpod only (checker: `banned-state`, `banned-package`, `manual-provider`, `provider-location`, `setstate-outside-ui`)

- Use `flutter_riverpod` with `riverpod_annotation` / `riverpod_generator`.
  **Every provider is declared with `@riverpod` codegen.** Hand-written
  `Provider(...)`, `FutureProvider(...)` etc. are rejected.
- Providers live in `application/`. Infrastructure providers (Supabase
  client, logger, config) live in `core/`.
- Banned everywhere: `ChangeNotifier`, `ValueNotifier`, `StateNotifier`,
  `StateProvider`, `InheritedWidget`, and the packages `provider`, `bloc`,
  `get`, `mobx` and `flutter_hooks`/`hooks_riverpod`.
- `setState` is only allowed in `presentation/` and `core/widgets/`, and
  only for ephemeral UI state (animation, focus, a text controller's
  transient value). Anything another widget, screen or test could care
  about belongs in a notifier. Review enforces that distinction.
- Widgets that read state are `ConsumerWidget` / `ConsumerStatefulWidget`.
  They `ref.watch` in `build` and `ref.read(...notifier)` in callbacks.
  Business logic never goes in `build`.
- Async state is `AsyncValue`. Screens handle `loading`, `error` and `data`
  explicitly.
- Repositories are exposed as providers (`@riverpod MapRepository
  mapRepository(Ref ref) => ...`) so tests override them. There are no
  static singletons: use `ref.watch(supabaseClientProvider)`, not
  `Supabase.instance` (checker: `supabase-instance`).
- Generated `*.g.dart` files are committed. CI fails if they're stale.

## 4. Size and shape (checker: `file-length`)

- A file may have at most **300 lines**. The only exemptions are
  static-data files listed with a reason in `LONG_FILE_EXEMPTIONS`.
- Aim for one public widget or class per file. A private helper widget
  that grows past about 50 lines gets its own file.
- `app.dart` only builds `MaterialApp.router`. Start-up and onboarding
  gating go in `app/router.dart` redirects driven by providers, not in a
  hand-rolled `StatefulWidget` state machine.

## 5. Routing

- Use `go_router`, configured in `lib/src/app/router.dart` and exposed as
  a `@riverpod` provider.
- Auth and onboarding gating are `redirect` rules that read auth and
  onboarding providers.

## 6. Tests

- Tests mirror `lib/src/` under `test/`, for example
  `test/features/auth/application/sign_in_controller_test.dart`.
- Every notifier and repository gets unit tests using
  `ProviderContainer` with overridden repositories. Screens get at least a
  smoke widget test.
- Tests never hit a real Supabase project.

## 7. Existing debt

`tools/architecture_baseline.json` lists violations that existed when the
guard was introduced (the imported v2 onboarding code). The baseline only
ever shrinks: a PR that pays debt down must regenerate it
(`--update-baseline`), and CI rejects any PR that grows it compared with
`main`.

## 8. Changing these rules

Rules change by PR only, editing this file and `tools/check_architecture.py`
together. CODEOWNERS makes the repo owner a required reviewer for both.
