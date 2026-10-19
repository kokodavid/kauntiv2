import '../domain/check_in_outcome.dart';

/// The sentence under the button for each way a check-in can end.
String checkInMessage(CheckInOutcome outcome, String placeName) {
  final failure = outcome.failure;
  if (failure == null) {
    return outcome.already
        ? "You've already checked in here today."
        : "Checked in. $placeName is now in your passport.";
  }
  return switch (failure) {
    CheckInFailure.noLocation =>
      "We couldn't get your location. Check that location is on for "
          'Kaunti47, then try again.',
    CheckInFailure.lowAccuracy =>
      "Your location isn't precise enough yet. Wait a moment, or step "
          'somewhere with a clearer sky, then try again.',
    CheckInFailure.tooFar => _tooFar(outcome, placeName),
    CheckInFailure.dailyLimit =>
      "You've reached today's check-in limit. Try again tomorrow.",
    CheckInFailure.placeUnavailable =>
      "This place can't be checked in at right now.",
    CheckInFailure.paused => 'Check-ins are paused right now.',
  };
}

String _tooFar(CheckInOutcome outcome, String placeName) {
  final distance = outcome.distanceMeters;
  final radius = outcome.radiusMeters;
  if (distance == null || radius == null) {
    return "You don't seem to be at $placeName yet.";
  }
  return "You're about ${_length(distance)} from $placeName. "
      'Get within ${_length(radius)} and try again.';
}

String _length(int meters) {
  if (meters < 1000) return '${(meters / 10).round() * 10} m';
  final km = meters / 1000;
  return '${km.toStringAsFixed(km < 10 ? 1 : 0)} km';
}

/// Shown when the request itself failed (offline, server error).
const checkInErrorMessage =
    "Couldn't check in. Check your connection and try again.";
