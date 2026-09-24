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
                    now.subtract(_speedCheckWindow),
                  ),
            ))
            .get();
    final seenAt = <int, DateTime>{
      for (final c in others)
        if (now.difference(c.enteredAt) <= _speedCheckWindow)
          c.countyCode: c.enteredAt,
      for (final p in recentOps) p.countyCode: p.resolvedAt,
    };
    for (final MapEntry(key: other, value: at) in seenAt.entries) {
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
