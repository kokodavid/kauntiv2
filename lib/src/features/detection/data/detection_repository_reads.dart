part of 'detection_repository.dart';

/// Read-only views of detection's local state.
extension DetectionQueueReads on DetectionRepository {
  Future<Set<int>> pendingCountyCodes() async => {
    for (final visit in await queuedVisits()) visit.countyCode,
  };

  Future<Set<int>> activeCandidateCountyCodes() async => {
    for (final nudge in await activeArrivalCandidates()) nudge.countyCode,
  };

  Future<List<ResolvedVisit>> queuedVisits() async {
    final owner = await _ownerId();
    final rows = await (_db.select(
      _db.pendingSyncOps,
    )..where((t) => _ownedBy(t, owner))).get();
    return [
      for (final row in rows)
        ResolvedVisit(
          countyCode: row.countyCode,
          outcome: VisitOutcome.fromWire(row.outcome),
          enteredAt: row.enteredAt,
          resolvedAt: row.resolvedAt,
        ),
    ];
  }

  Future<List<CountyArrivalNudge>> activeArrivalCandidates() async {
    await _ownerId();
    final rows = await _db.select(_db.candidates).get();
    return [
      for (final row in rows)
        CountyArrivalNudge(
          countyCode: row.countyCode,
          enteredAt: row.enteredAt,
        ),
    ];
  }
}

/// The speed sanity check behind [DetectionRepository.handleEvent].
extension _SpeedSanity on DetectionRepository {
  /// Speed sanity: a new candidate is rejected when reaching it from
  /// another county seen in the last 15 minutes would need an impossible
  /// speed (county centroid to centroid).
  Future<bool> _isPlausibleNewCandidate(int countyCode, DateTime now) async {
    final owner = await _ownerId();
    final others = await (_db.select(
      _db.candidates,
    )..where((c) => c.countyCode.equals(countyCode).not())).get();
    final recentOps =
        await (_db.select(_db.pendingSyncOps)..where(
              (p) =>
                  _ownedBy(p, owner) &
                  p.countyCode.equals(countyCode).not() &
                  p.resolvedAt.isBiggerThanValue(
                    now.subtract(DetectionRepository._speedCheckWindow),
                  ),
            ))
            .get();
    final seenAt = <int, DateTime>{
      for (final c in others)
        if (now.difference(c.enteredAt) <=
            DetectionRepository._speedCheckWindow)
          c.countyCode: c.enteredAt,
      for (final p in recentOps) p.countyCode: p.resolvedAt,
    };
    for (final MapEntry(key: other, value: at) in seenAt.entries) {
      // Neighbours share a border: crossing between them can take no time
      // at all. Centre to centre is not how far the phone travelled (big
      // counties are 80 km or more apart that way), and measuring it
      // that way held a real crossing back until the 15 minute window
      // had passed, which cut the new county's stay short.
      if (CountyPaths.neighborCodes[countyCode]?.contains(other) ?? false) {
        continue;
      }
      final meters = CountyDistance.betweenCentroids(countyCode, other);
      if (meters == null) continue;
      if (!VisitRules.isPlausibleTransition(
        distanceMeters: meters,
        elapsed: now.difference(at).abs(),
      )) {
        return false;
      }
    }
    return true;
  }
}

/// Closing the timers a fix proves are over.
extension _CandidateClosing on DetectionRepository {
  /// Ends every running timer except [except]'s, at [at]. A timer that
  /// ran under the flap guard is dropped (it was a border blip, and left
  /// alone it would later resolve as explored); the rest resolve the normal
  /// way: explored after the dwell threshold, otherwise passed through.
  Future<void> _closeOtherCandidates({
    required int except,
    required DateTime at,
  }) async {
    await _ownerId();
    final others = await (_db.select(
      _db.candidates,
    )..where((c) => c.countyCode.equals(except).not())).get();
    for (final candidate in others) {
      // A fix older than the timer says nothing about it (a late or cached
      // fix must not cancel a stay that began after it was taken).
      if (candidate.enteredAt.isAfter(at)) continue;
      final decision = rules.onExit(
        candidateEnteredAt: candidate.enteredAt,
        now: at,
      );
      if (decision.action == VisitAction.ignore) {
        await (_db.delete(
          _db.candidates,
        )..where((c) => c.countyCode.equals(candidate.countyCode))).go();
        continue;
      }
      await _resolve(
        countyCode: candidate.countyCode,
        outcome: decision.action == VisitAction.resolveExplored
            ? VisitOutcome.explored
            : VisitOutcome.passedThrough,
        enteredAt: candidate.enteredAt,
        resolvedAt: at,
      );
    }
  }
}
