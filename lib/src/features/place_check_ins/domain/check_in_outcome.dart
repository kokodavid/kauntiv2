/// Why a check-in didn't count. Each has a plain sentence for the card.
enum CheckInFailure {
  /// No position: permission off, services off, or no fix in time.
  noLocation,

  /// The fix was old or too loose to say where the person is.
  lowAccuracy,

  /// Further from the place than its radius allows.
  tooFar,

  /// Too many check-ins today.
  dailyLimit,

  /// The place can't be checked in at (not published, or removed).
  placeUnavailable,

  /// The feature is paused.
  paused,
}

/// The server's answer to "I'm here".
class CheckInOutcome {
  const CheckInOutcome.counted({
    required this.already,
    this.distanceMeters,
    this.radiusMeters,
  }) : failure = null;

  const CheckInOutcome.failed(
    CheckInFailure this.failure, {
    this.distanceMeters,
    this.radiusMeters,
  }) : already = false;

  /// Null when the check-in counted.
  final CheckInFailure? failure;

  /// True when this place was already checked in today (nothing new added).
  final bool already;

  final int? distanceMeters;
  final int? radiusMeters;

  bool get counted => failure == null;

  /// How far outside the radius, when it was too far.
  int? get metersOver {
    final d = distanceMeters;
    final r = radiusMeters;
    return d == null || r == null ? null : (d - r).clamp(0, 1 << 31);
  }
}

/// What the place page needs to draw the card.
class PlaceCheckInStatus {
  const PlaceCheckInStatus({
    this.enabled = false,
    this.checkedInToday = false,
    this.visits = 0,
  });

  final bool enabled;
  final bool checkedInToday;

  /// Distinct days this place has been checked in at.
  final int visits;
}
