part of 'detection_repository.dart';

/// Whether a fix shows the phone in transit (the state it keeps is the
/// repository's own `_lastFix` and `_pendingBorder`).
extension _TransitCheck on DetectionRepository {
  /// Whether this fix shows the phone moving faster than road speed since the
  /// last one. In transit nothing is credited and entries are held back; the
  /// first fix that is no longer fast clears it, so the visit starts there
  /// and its dwell clock starts fresh. A loose fix is not used for speed.
  Future<bool> _inTransit(
    double latitude,
    double longitude,
    DateTime at,
    double? accuracyMeters,
  ) async {
    if (accuracyMeters != null &&
        accuracyMeters > gate.config.maxAccuracyMeters) {
      return false;
    }
    final last = _lastFix;
    _lastFix = (latitude: latitude, longitude: longitude, at: at);
    final fast =
        last != null &&
        transitRules.isTransit(
          fromLatitude: last.latitude,
          fromLongitude: last.longitude,
          fromAt: last.at,
          toLatitude: latitude,
          toLongitude: longitude,
          toAt: at,
        );
    if (fast) {
      _pendingBorder = null;
      await outcomes.add(DetectionOutcome.transit);
      await transitFlag.markUntil(at.add(transitRules.config.hold));
      return true;
    }
    if (last != null &&
        at.difference(last.at) >= transitRules.config.minElapsed) {
      await transitFlag.clear();
    }
    return false;
  }
}

/// Writes to detection's local state.
extension _QueueWrites on DetectionRepository {
  /// Moves a candidate into the sync queue, once: a candidate already
  /// resolved (or restarted since) is left alone.
  Future<ResolvedVisit?> _resolve({
    required int countyCode,
    required VisitOutcome outcome,
    required DateTime enteredAt,
    required DateTime resolvedAt,
  }) async {
    await _ready;
    final enteredAtUtc = enteredAt.toUtc();
    final resolvedAtUtc = resolvedAt.toUtc();
    final queued = await _db.transaction(() async {
      final owner = await _ownerId();
      final candidate = await (_db.select(
        _db.candidates,
      )..where((c) => c.countyCode.equals(countyCode))).getSingleOrNull();
      if (candidate == null || candidate.enteredAt != enteredAt) return false;
      await (_db.delete(
        _db.candidates,
      )..where((c) => c.countyCode.equals(countyCode))).go();
      await _db
          .into(_db.pendingSyncOps)
          .insert(
            PendingSyncOpsCompanion.insert(
              userId: Value(owner),
              countyCode: countyCode,
              outcome: outcome.wireName,
              enteredAt: enteredAtUtc,
              resolvedAt: resolvedAtUtc,
            ),
          );
      return true;
    });
    if (!queued) return null;
    return ResolvedVisit(
      countyCode: countyCode,
      outcome: outcome,
      enteredAt: enteredAtUtc,
      resolvedAt: resolvedAtUtc,
    );
  }

  Future<void> _setCurrentCounty(int countyCode) async {
    await _ready;
    await _db.transaction(() async {
      await _ownerId();
      await _db
          .into(_db.currentCounty)
          .insertOnConflictUpdate(
            CurrentCountyCompanion.insert(
              id: const Value(DetectionRepository._currentCountyRowId),
              countyCode: countyCode,
              updatedAt: DateTime.now(),
            ),
          );
    });
  }
}

/// Sign-out.
extension DetectionLocalReset on DetectionRepository {
  /// Sign-out: drops this owner's timers, queue and binding.
  Future<void> clearAllLocalState() async {
    await _ready;
    await _db.transaction(() async {
      final owner = await _ownerId();
      await _db.delete(_db.candidates).go();
      if (owner != null) {
        await (_db.delete(
          _db.pendingSyncOps,
        )..where((t) => t.userId.equals(owner))).go();
      }
      await _db.delete(_db.currentCounty).go();
      await _db.delete(_db.detectionOwner).go();
    });
  }
}
