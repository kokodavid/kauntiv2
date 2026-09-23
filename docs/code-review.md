# Code review checklist

This checklist is used on every PR by the Claude review workflow
(`.github/workflows/claude-review.yml`) and by human reviewers. CI already
proves the mechanical rules; review covers what a script can't judge.

## Blocking

- [ ] **The right layer.** Logic sits in `application/` or `data/`, not in
      widgets. Screens only render state and forward events.
- [ ] **Riverpod used properly:**
  - `ref.watch` in `build`, `ref.read` in callbacks
  - no `ref` use after `await` without a `ref.mounted` check
  - `keepAlive` only when justified
  - no provider created inside `build`
- [ ] **setState is ephemeral only.** Anything another widget or test could
      care about is in a notifier.
- [ ] **Async and error states handled.** `AsyncValue` loading, error and
      data are all rendered. There are no silent `catch (_) {}`.
- [ ] **Data layer returns domain models.** Raw Supabase maps and rows
      never leak past `data/`.
- [ ] **Supabase.** RLS assumptions are stated. New tables or columns come
      with a migration. Applied migrations are never edited.
- [ ] **Tests.** New notifiers and repositories have unit tests with
      overridden dependencies.
- [ ] **Scope.** One feature per PR, with no drive-by changes.
- [ ] **Faithful to the design.** Colors, fonts and geometry come from
      `core/design` tokens and the design canvas, with no ad-hoc hex values.

## Watch for bloat (v1's failure mode)

- A file approaching 300 lines, or a widget `build` method longer than
  about 80 lines.
- A private `_Something` widget that has grown big enough to deserve its
  own file.
- The same helper written twice. It should move to `core/`.
- Flags and booleans piling up in one class. That's a state machine
  asking to be modeled explicitly.

## Housekeeping

- [ ] `docs/port-tracker.md` is updated.
- [ ] `tools/architecture_baseline.json` stayed the same or shrank.
- [ ] The PR description lists what was verified and what wasn't.
