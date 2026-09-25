import '../domain/journey_fix.dart';
import '../domain/pro_status.dart';

/// What to tell the user when a Journey can't start or resume.
abstract final class JourneyMessages {
  static const proRequiredTitle = 'Journeys are part of Pro';
  static const proRequiredBody =
      'Recording your route needs an active Kaunti47 Pro plan. Your past '
      'Journeys stay yours to view and delete either way.';

  /// Null for errors the screen handles itself ([JourneyStartDenied]).
  static String? forError(Object error) => switch (error) {
    JourneyStartDenied() => null,
    JourneyProCheckUnavailable() =>
      'Connect to the internet to start a Journey.',
    JourneyLocationException(:final reason) => switch (reason) {
      JourneyLocationFailure.servicesDisabled =>
        'Turn on location services to record a Journey.',
      JourneyLocationFailure.permissionDenied ||
      JourneyLocationFailure.backgroundPermissionDenied =>
        'Allow location "All the time" in Settings to record your route '
            'while the phone is locked.',
      JourneyLocationFailure.backgroundModeUnavailable ||
      JourneyLocationFailure.settingsUnavailable =>
        "This phone couldn't start recording in the background.",
    },
    _ => "Couldn't start the Journey. Try again.",
  };

  /// Whether the fix for [error] is in the phone's Settings.
  static bool opensSettings(Object error) =>
      error is JourneyLocationException &&
      (error.reason == JourneyLocationFailure.permissionDenied ||
          error.reason == JourneyLocationFailure.backgroundPermissionDenied);
}
