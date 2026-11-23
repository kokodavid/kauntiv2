/// Why a Trip is paused. A pause the person asked for is [user]; the others
/// are pauses the app made because recording could not carry on.
enum JourneyPauseReason {
  /// The person tapped Pause.
  user,

  /// The location stream stopped and could not be restarted in time.
  locationLost,

  /// The app was closed or killed, and the saved Trip was recovered paused.
  appRestarted,

  /// The Trip never got a first fix, or location access was missing.
  startFailed,

  /// The signed-in account changed while recording.
  accountChanged,

  /// A pause recorded before reasons existed.
  unknown;

  /// True when the app, not the person, paused the Trip.
  bool get isSystem => switch (this) {
    locationLost || appRestarted || startFailed || accountChanged => true,
    user || unknown => false,
  };

  String get storageValue => switch (this) {
    user => 'user',
    locationLost => 'location_lost',
    appRestarted => 'app_restarted',
    startFailed => 'start_failed',
    accountChanged => 'account_changed',
    unknown => 'unknown',
  };

  /// The reason saved in the local database; null when none was saved (a
  /// Trip that is not paused, or was paused before reasons existed).
  static JourneyPauseReason? fromStorage(String? value) {
    if (value == null) return null;
    for (final reason in values) {
      if (reason.storageValue == value) return reason;
    }
    return JourneyPauseReason.unknown;
  }
}
