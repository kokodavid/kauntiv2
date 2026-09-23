## What & why

<!-- One feature per PR. Link the port-tracker row. -->

## Layers touched

- [ ] domain  - [ ] data  - [ ] application  - [ ] presentation  - [ ] core  - [ ] app

## Checklist

- [ ] `dart format lib test`
- [ ] `dart run build_runner build --delete-conflicting-outputs` (generated files committed)
- [ ] `flutter analyze --fatal-infos`
- [ ] `dart run custom_lint`
- [ ] `python3 tools/check_architecture.py`
- [ ] `flutter test`
- [ ] Tests added for new notifiers/repositories
- [ ] `docs/port-tracker.md` updated
- [ ] Architecture baseline unchanged or smaller

## Verified / not verified

<!-- Say exactly what you ran and on what (simulator, device, dev Supabase). List anything you could NOT verify. -->
