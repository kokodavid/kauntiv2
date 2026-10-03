# Dev Location Diagnostics

The diagnostics tool is enabled only when `LOCATION_DIAGNOSTICS=true` is
compiled into the dev flavor. The dev VS Code launch configuration reads
`dart_defines/dev.json`; production does not enable the tool. The app also
checks that its runtime `AppConfig` is dev before exposing the Profile entry.

## Collect a report

1. Install and open a dev build on the test phone.
2. Open **Profile → Location diagnostics**, then tap **Start session**.
3. Use the app normally, including a locked-screen Journey if that is what is
   being measured. Keep Xcode Energy Log or Android Battery Historian running
   separately for app-level energy attribution.
4. Return to the app, tap **Stop session**, then **Share report**. Attach the
   `.jsonl` file to the engineering task. **Copy summary** is useful for a
   quick comparison, but the JSONL file contains the event timeline.

Reports stay in application-support storage on that device until cleared or
the app is removed. They contain UTC timestamps, battery percentage samples,
Detection cycle/read counts, geofence transition kinds, Journey start/stop
events, transport mode, and gaps that caused Journey segment splits. They do
not contain coordinates, account IDs, or place names. Sharing is an explicit
user action; the app does not upload diagnostics.

Battery percentage is coarse and affected by other device activity. Compare
matched runs and platform profiler data; do not treat the percentage delta as
an app-only energy measurement. Background battery samples are not continuous,
especially on iOS, so platform profiling remains necessary for multi-hour
locked-screen tests.
