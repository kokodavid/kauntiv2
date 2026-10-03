/// Build-time switches for features that exist in the code but aren't
/// released yet. Turn one on with a dart-define, e.g.
/// `--dart-define=JOURNEYS_ENABLED=true`.
abstract final class AppFeatureFlags {
  /// The Journeys tab (Pro route recording). Hidden until release
  /// readiness (docs/journeys-plan.md step 5).
  static const journeys = bool.fromEnvironment('JOURNEYS_ENABLED');

  /// The Ranks tab (leaderboards). Hidden from the tab bar until the
  /// screen is ported.
  static const ranks = bool.fromEnvironment('RANKS_ENABLED');

  /// Local location and battery diagnostics for dev builds only.
  static const locationDiagnostics = bool.fromEnvironment(
    'LOCATION_DIAGNOSTICS',
  );
}
