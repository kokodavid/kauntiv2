# App Environments

Kaunti47 uses two app environments: `dev` and `prod`. The app environment is
selected by the Flutter entrypoint and the native platform flavor/scheme.

## Environment Model

| Environment | Flutter target | Android flavor | iOS scheme | App label | Android package / iOS bundle ID |
|---|---|---|---|---|---|
| Dev | `lib/main_dev.dart` | `dev` | `dev` | `Kaunti47 Dev` | `com.giglab.kaunti47` / `com.giglab.kaunti47.app` |
| Prod | `lib/main_prod.dart` | `prod` | `prod` | `Kaunti47` | `com.giglab.kaunti47` / `com.giglab.kaunti47.app` |

Both flavors intentionally share the same Android package name and iOS bundle
identifier. This keeps store setup to one app record. The tradeoff is that dev
and prod builds cannot be installed side-by-side on the same device; installing
one replaces the other.

The default `lib/main.dart` entrypoint runs the production config for IDEs or
tools that launch the default Flutter target.

## Supabase Environments

Supabase environments should be handled as two separate Supabase projects:

| App environment | Supabase project | Purpose |
|---|---|---|
| Dev | Dev Supabase project | Test data, schema iteration, sandbox callbacks |
| Prod | Prod Supabase project | Real users, locked-down RLS, production callbacks |

Apply database migrations to the dev project first. After review, apply the
same migrations to production. Do not let dev and prod drift intentionally; if
they differ, document the reason in `docs/port-tracker.md`.

## Auth Redirect URLs

OAuth sign-in returns to the app through environment-specific deep links:

| Environment | Redirect URL |
|---|---|
| Dev | `kaunti47-dev://login-callback` |
| Prod | `kaunti47-prod://login-callback` |

Add only the matching URL to each Supabase project's redirect allow list. The
native Android and iOS projects are configured to open these URLs for their
matching flavor/scheme.

## Runtime Defines

Supabase client values are passed at build/run time:

```bash
--dart-define=SUPABASE_URL=<supabase-project-url>
--dart-define=SUPABASE_PUBLISHABLE_KEY=<supabase-publishable-key>
```

The Supabase publishable key is designed for client apps, but it should still
not be hardcoded in source. Keeping it in build configuration avoids mixing
projects accidentally and keeps local development flexible.

For local development, copy the example files and fill them with values from
the matching Supabase project:

```bash
cp dart_defines/dev.example.json dart_defines/dev.json
cp dart_defines/prod.example.json dart_defines/prod.json
```

The filled `dart_defines/dev.json` and `dart_defines/prod.json` files are
ignored by Git. Only the placeholder `*.example.json` templates are committed.

## Android Commands

Run dev:

```bash
flutter run --flavor dev -t lib/main_dev.dart \
  --dart-define-from-file=dart_defines/dev.json
```

Build dev debug APK:

```bash
flutter build apk --debug --flavor dev -t lib/main_dev.dart \
  --dart-define-from-file=dart_defines/dev.json
```

## Release Signing (Android)

`android/app/build.gradle.kts`'s `release` build type signs with a real
keystore when `android/key.properties` is present, falling back to the debug
keystore otherwise (so a fresh checkout or an unprovisioned CI runner still
builds). Both `android/key.properties` and `android/keystore/` are
git-ignored -- generated once per machine, never committed.

Generate a keystore (only needs doing once; keep the file and passwords
backed up somewhere safe outside the repo -- losing them means a future
release can never be signed to match one already distributed):

```bash
keytool -genkeypair -v \
  -keystore android/keystore/kaunti47-release.jks \
  -alias kaunti47 \
  -keyalg RSA -keysize 2048 -validity 10000
```

Then create `android/key.properties`:

```properties
storePassword=<store password>
keyPassword=<key password>
keyAlias=kaunti47
storeFile=keystore/kaunti47-release.jks
```

(`storeFile` is relative to `android/`, not `android/app/`.)

Build a signed release APK for internal testing, from the dev environment:

```bash
flutter build apk --release --flavor dev -t lib/main_dev.dart \
  --dart-define-from-file=dart_defines/dev.json
```

Build a signed app bundle instead (needed for the Play Console's Internal
Testing track, which does not accept a raw APK):

```bash
flutter build appbundle --release --flavor dev -t lib/main_dev.dart \
  --dart-define-from-file=dart_defines/dev.json
```

Swap `--flavor dev -t lib/main_dev.dart --dart-define-from-file=dart_defines/dev.json`
for the `prod` equivalents to sign a production build the same way -- both
flavors reuse the same keystore/signing config, since they share one
application ID (see the Environment Model table above).

Run prod:

```bash
flutter run --flavor prod -t lib/main_prod.dart \
  --dart-define-from-file=dart_defines/prod.json
```

Build prod debug APK:

```bash
flutter build apk --debug --flavor prod -t lib/main_prod.dart \
  --dart-define-from-file=dart_defines/prod.json
```

## iOS Commands

iOS is configured with `dev` and `prod` shared schemes plus matching build
configurations:

- `Debug-dev`, `Profile-dev`, `Release-dev`
- `Debug-prod`, `Profile-prod`, `Release-prod`

Builds require a Mac with Xcode signing configured for `com.giglab.kaunti47.app`.

Run dev:

```bash
flutter run --flavor dev -t lib/main_dev.dart \
  --dart-define-from-file=dart_defines/dev.json
```

Build prod:

```bash
flutter build ios --flavor prod -t lib/main_prod.dart \
  --dart-define-from-file=dart_defines/prod.json
```

### iOS Simulator CodeSign/Libtool Failures In iCloud Paths

If an iOS simulator run fails after Xcode has built with generic errors like:

```text
Command CodeSign failed with a nonzero exit code
Command Libtool failed with a nonzero exit code
```

check whether the checkout is inside iCloud Drive or a synced `Documents`
location. Xcode may report only the generic `CodeSign`/`Libtool` failures even
though the underlying signing error is:

```text
resource fork, Finder information, or similar detritus not allowed
```

The durable fix is to move the repository out of any iCloud/File Provider synced
path. Prefer a local path such as:

```text
/Users/<user>/Projects/kaunti47
```

Avoid paths such as:

```text
/Users/<user>/Documents/...
/Users/<user>/Library/Mobile Documents/...
/Users/<user>/iCloud Drive/...
```

After moving the checkout, rebuild the local generated state from the new path:

```bash
flutter clean
flutter pub get
cd ios
pod install
cd ..
```

Then run the desired flavor again:

```bash
flutter run --flavor dev -t lib/main_dev.dart \
  --dart-define-from-file=dart_defines/dev.json
```

To confirm the diagnosis before moving, inspect generated iOS native artifacts:

```bash
xattr -lr build/native_assets/ios
```

Extended attributes such as `com.apple.FinderInfo`,
`com.apple.fileprovider.fpfs#P`, or `com.apple.provenance` on generated
frameworks confirm the iCloud/File Provider metadata problem. A temporary local
cleanup is:

```bash
xattr -cr build
```

Use that only as a short-term unblocker. iCloud can reattach the metadata after
cleanup, so keeping the repo outside synced folders is the reliable fix.

## Current Scope

The environment setup PR added app-side environment selection. The Supabase
bootstrap PR installs and initializes the Supabase Flutter SDK from the runtime
defines above. `SUPABASE_ANON_KEY` is still accepted as a fallback define for
older Supabase project settings, but `SUPABASE_PUBLISHABLE_KEY` is preferred.
Database schema, migrations, and RLS policies are handled in the Supabase
schema PR.
