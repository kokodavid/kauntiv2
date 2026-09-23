# Kaunti47 v2

This is a Flutter + Supabase app that badges you for each of Kenya's 47
counties you physically enter. v2 is a clean rebuild of v1
(`kokodavid/kaunti47`) with enforced architecture.

- **Rules:** [`AGENTS.md`](AGENTS.md), [`docs/architecture.md`](docs/architecture.md)
- **Review checklist:** [`docs/code-review.md`](docs/code-review.md)
- **Port progress:** [`docs/port-tracker.md`](docs/port-tracker.md)
- **Environments / running:** [`docs/app-environments.md`](docs/app-environments.md)

## Run

```bash
cp dart_defines/dev.example.json dart_defines/dev.json   # fill in values
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run --flavor dev -t lib/main_dev.dart --dart-define-from-file=dart_defines/dev.json
```

## Checks (the same ones CI runs)

```bash
dart format lib test
flutter analyze --fatal-infos
dart run custom_lint
python3 tools/check_architecture.py
flutter test
```
