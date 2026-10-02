import '../domain/journey_fix.dart';
import '../domain/pro_status.dart';

/// What to tell the user when a Journey can't start or resume.
abstract final class JourneyMessages {
  static const trialExhaustedTitle = "You've used your free Trips";
  static const trialExhaustedBody =
      "You've recorded 3 Trips this month, the limit on the free plan. "
      'Upgrade to Pro for unlimited Trips, or try again after it resets '
      'on the 1st.';

  /// Null for errors the screen handles itself ([JourneyTrialExhausted]).
  static String? forError(Object error) => switch (error) {
    JourneyTrialExhausted() => null,
    JourneyProCheckUnavailable() => 'Connect to the internet to start a Trip.',
    JourneyTeardownException() =>
      'Location capture has not stopped yet. Please try again.',
    JourneyLocationException(:final reason) => switch (reason) {
      JourneyLocationFailure.servicesDisabled =>
        'Turn on location services to record a Trip.',
      JourneyLocationFailure.permissionDenied ||
      JourneyLocationFailure.backgroundPermissionDenied =>
        'Allow location "All the time" in Settings to record your route '
            'while the phone is locked.',
      JourneyLocationFailure.backgroundModeUnavailable ||
      JourneyLocationFailure.settingsUnavailable =>
        "This phone couldn't start recording in the background.",
      JourneyLocationFailure.noFixReceived =>
        "Couldn't get a GPS signal. Move somewhere with a clearer view of "
            'the sky and try again.',
    },
    _ => "Couldn't start the Trip. Try again.",
  };

  /// Whether the fix for [error] is in the phone's Settings.
  static bool opensSettings(Object error) =>
      error is JourneyLocationException &&
      (error.reason == JourneyLocationFailure.permissionDenied ||
          error.reason == JourneyLocationFailure.backgroundPermissionDenied);
}
