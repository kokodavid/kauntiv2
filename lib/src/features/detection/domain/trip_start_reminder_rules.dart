/// The payload of the local "Looks like you're on a trip" notification, so
/// a tap on it can be told apart from an arrival or a paused-trip reminder.
const tripStartPayload = 'trip_start';

/// When the phone may suggest recording a Trip. Pure, so the geofence
/// callback (no providers) and the tests share it.
///
/// Only a county crossing triggers it, which means the person is moving
/// between counties. The reminder stays quiet when the switch is off, when
/// the account can't start a Trip, while a Trip is already recording, soon
/// after a Trip ended, and after one reminder in a day.
abstract final class TripStartReminderRules {
  /// At most one reminder in this long.
  static const minGap = Duration(hours: 24);

  /// No reminder this soon after a Trip ended: they just stopped on purpose.
  static const afterTripQuiet = Duration(minutes: 30);

  static bool isDue({
    required bool enabled,
    required bool eligible,
    required bool recording,
    required DateTime now,
    DateTime? lastTripEndedAt,
    DateTime? lastRemindedAt,
  }) {
    if (!enabled || !eligible || recording) return false;
    final ended = lastTripEndedAt;
    if (ended != null && now.difference(ended) < afterTripQuiet) return false;
    final reminded = lastRemindedAt;
    if (reminded != null && now.difference(reminded) < minGap) return false;
    return true;
  }
}
