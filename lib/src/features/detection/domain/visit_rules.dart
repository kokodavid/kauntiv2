/// What a crossing event, or a periodic check on a still-running
/// candidate, should do next.
enum VisitAction {
  /// Start tracking a new candidate window for this county.
  startCandidate,

  /// The dwell threshold was met: resolve as explored.
  resolveExplored,

  /// Left before the dwell threshold: resolve as passed through.
  resolvePassedThrough,

  /// Nothing to do: a duplicate, a boundary flap, or an EXIT with no
  /// matching candidate.
  ignore,
}

class VisitDecision {
  const VisitDecision(this.action, {this.enteredAt});

  final VisitAction action;

  /// For [VisitAction.startCandidate], when the window starts; for a
  /// resolve, when the original candidate window started.
  final DateTime? enteredAt;
}

/// Doc 01's timings. Production: stay 2 h to explore, exits within 2 min
/// are boundary flaps. Dev (emulator QA): 2 min and 15 s.
class VisitTimings {
  const VisitTimings({required this.dwellThreshold, required this.flapGuard});

  static const production = VisitTimings(
    dwellThreshold: Duration(hours: 2),
    flapGuard: Duration(minutes: 2),
  );

  static const dev = VisitTimings(
    dwellThreshold: Duration(minutes: 2),
    flapGuard: Duration(seconds: 15),
  );

  final Duration dwellThreshold;
  final Duration flapGuard;
}

/// Doc 01's visit state machine (candidate → explored / passed through),
/// with the flap guard and speed sanity check. Pure decisions: the caller
/// persists candidates, since they must survive the OS killing the app
/// mid-dwell.
class VisitRules {
  const VisitRules(this.timings);

  final VisitTimings timings;

  /// Well above any real road speed (~216 km/h): only impossible jumps
  /// (spoofing, a bad fix) are rejected, not fast driving.
  static const maxPlausibleSpeedMetersPerSecond = 60.0;

  /// ENTER starts a candidate. An ENTER for a county that already has one
  /// is a duplicate (the OS can redeliver after a reboot) and is ignored
  /// rather than restarting the window.
  VisitDecision onEnter({
    required DateTime? existingCandidateEnteredAt,
    required DateTime now,
  }) {
    if (existingCandidateEnteredAt != null) {
      return const VisitDecision(VisitAction.ignore);
    }
    return VisitDecision(VisitAction.startCandidate, enteredAt: now);
  }

  /// EXIT resolves the matching candidate: explored after the dwell
  /// threshold, passed through before it, ignored inside the flap guard or
  /// with no candidate.
  VisitDecision onExit({
    required DateTime? candidateEnteredAt,
    required DateTime now,
  }) {
    if (candidateEnteredAt == null) {
      return const VisitDecision(VisitAction.ignore);
    }
    final dwell = now.difference(candidateEnteredAt);
    if (dwell < timings.flapGuard) {
      return const VisitDecision(VisitAction.ignore);
    }
    return VisitDecision(
      dwell >= timings.dwellThreshold
          ? VisitAction.resolveExplored
          : VisitAction.resolvePassedThrough,
      enteredAt: candidateEnteredAt,
    );
  }

  /// Neither platform reliably delivers "still inside after N hours", so a
  /// running candidate is checked whenever the app gets a chance (resume,
  /// another geofence event, a sync). Old enough: resolve as explored.
  VisitDecision checkStillCandidate({
    required DateTime candidateEnteredAt,
    required DateTime now,
  }) {
    if (now.difference(candidateEnteredAt) >= timings.dwellThreshold) {
      return VisitDecision(
        VisitAction.resolveExplored,
        enteredAt: candidateEnteredAt,
      );
    }
    return const VisitDecision(VisitAction.ignore);
  }

  /// Speed sanity: could [distanceMeters] be covered in [elapsed]?
  static bool isPlausibleTransition({
    required double distanceMeters,
    required Duration elapsed,
  }) {
    if (elapsed.inSeconds <= 0) {
      // Simultaneous triggers only make sense right on a shared border.
      return distanceMeters < 500;
    }
    return distanceMeters / elapsed.inSeconds <=
        maxPlausibleSpeedMetersPerSecond;
  }
}
