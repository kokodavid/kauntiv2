import 'package:drift/drift.dart';

import '../../../core/counties/county_boundary_resolver.dart';
import '../../../core/counties/county_distance.dart';
import '../../../counties/county_paths.dart';
import '../domain/confidence_gate.dart';
import '../domain/detection_health_report.dart';
import '../domain/transit_rules.dart';
import '../domain/visit_models.dart';
import '../domain/visit_rules.dart';
import 'detection_outcome_counts.dart';
import 'local/detection_database.dart';
import 'transit_flag.dart';

part 'detection_repository_reads.dart';
part 'detection_repository_writes.dart';

/// Detection's on-device state (ported from v1): which counties are being
/// timed, the current county, and the queue of resolved visits waiting to
/// sync. Every write is scoped to the signed-in owner, so one account's
/// dwell timers or queued visits never sync as another's.
///
/// Used from the foreground and from the geofence background isolate, so
/// it only touches the local database: no network, no providers.
class DetectionRepository {
  DetectionRepository(
    this._db, {
    String? userId,
    this.rules = const VisitRules(VisitTimings.production),
    this.gate = const ConfidenceGate(),
    this.transitRules = const TransitRules(),
    this.transitFlag = const TransitFlag(),
    this.outcomes = const DetectionOutcomeCounts(),
  }) : _expectedOwner = userId {
    _ready = userId == null ? _restoreOwner() : _bindOwner(userId);
  }

  final DetectionDatabase _db;
  final VisitRules rules;
  final ConfidenceGate gate;
  final TransitRules transitRules;
  final TransitFlag transitFlag;
  final DetectionOutcomeCounts outcomes;

  /// The previous accepted fix, in memory only (never stored, doc 05), to
  /// tell whether the phone moves faster than a road allows.
  ({double latitude, double longitude, DateTime at})? _lastFix;

  /// The first near-border fix of a possible crossing, waiting for a second
  /// in the same county (memory only: a background isolate credits nothing
  /// on one near-border fix).
  ({int county, DateTime at})? _pendingBorder;
  late final Future<void> _ready;
  String? _expectedOwner;

  /// Completes after the local account-scoped state is ready for use.
  Future<void> get ready => _ready;

  static const _currentCountyRowId = 0;

  /// How far back other counties count for the speed sanity check.
  static const _speedCheckWindow = Duration(minutes: 15);

  Future<void> _restoreOwner() async {
    _expectedOwner =
        (await _db.select(_db.detectionOwner).getSingleOrNull())?.userId;
  }

  /// A new account drops the previous one's timers and current county; its
  /// queued visits stay, still owned by it.
  Future<void> _bindOwner(String userId) => _db.transaction(() async {
    final owner = await _db.select(_db.detectionOwner).getSingleOrNull();
    if (owner?.userId == userId) return;
    await _db.delete(_db.candidates).go();
    await _db.delete(_db.currentCounty).go();
    await _db
        .into(_db.detectionOwner)
        .insertOnConflictUpdate(
          DetectionOwnerCompanion.insert(id: const Value(0), userId: userId),
        );
  });

  Future<String?> _ownerId() async {
    await _ready;
    final owner =
        (await _db.select(_db.detectionOwner).getSingleOrNull())?.userId;
    if (owner != _expectedOwner) throw StateError('Detection account changed');
    return owner;
  }

  Expression<bool> _ownedBy(PendingSyncOps t, String? owner) =>
      owner == null ? t.userId.isNull() : t.userId.equals(owner);

  Future<int?> currentCountyCode() async {
    await _ownerId();
    final row = await (_db.select(
      _db.currentCounty,
    )..where((c) => c.id.equals(_currentCountyRowId))).getSingleOrNull();
    return row?.countyCode;
  }

  /// Sets the current county without recording a crossing (first fix).
  Future<void> seedCurrentCounty(int countyCode) =>
      _setCurrentCounty(countyCode);

  /// Turns a location fix into crossings: when the fix is clearly inside
  /// a different county than the current one (500 m hysteresis), exits the
  /// old county and enters the new one. Returns the county entered, if a
  /// new candidate started. The fix itself is never stored (doc 05).
  Future<int?> reconcileCurrentLocation({
    required double latitude,
    required double longitude,
    double minimumInsideDistanceMeters =
        CountyBoundaryResolver.boundaryHysteresisMeters,
    double? accuracyMeters,
    DateTime? now,
  }) async {
    final fixAt = now ?? DateTime.now();
    if (await _inTransit(latitude, longitude, fixAt, accuracyMeters)) {
      return null;
    }
    final sampled = CountyBoundaryResolver.countyCodeFor(
      latitude: latitude,
      longitude: longitude,
      minimumInsideDistanceMeters: minimumInsideDistanceMeters,
    );
    if (sampled == null) return null;
    final at = now ?? DateTime.now();
    final previous = await currentCountyCode();
    // The gate guards crossings only: a fix in the current county changes
    // nothing, and the very first fix just seeds it.
    if (previous != null && previous != sampled) {
      final inside =
          CountyBoundaryResolver.insideDistanceMeters(
            latitude: latitude,
            longitude: longitude,
            code: sampled,
          ) ??
          0;
      final pending = _pendingBorder;
      final fresh =
          pending != null &&
          pending.county == sampled &&
          at.difference(pending.at) >= gate.config.confirmGap &&
          at.difference(pending.at) <= gate.config.confirmWindow;
      switch (gate.judge(
        accuracyMeters: accuracyMeters,
        insideMeters: inside,
        alreadyPending: fresh,
      )) {
        case GateVerdict.reject:
          await outcomes.add(DetectionOutcome.rejectedAccuracy);
          return null;
        case GateVerdict.needConfirmation:
          await outcomes.add(DetectionOutcome.heldBorder);
          // Keep the older fix if it is still fresh enough to confirm on the
          // next one; otherwise start over from this fix.
          if (pending == null ||
              pending.county != sampled ||
              at.difference(pending.at) > gate.config.confirmWindow) {
            _pendingBorder = (county: sampled, at: at);
          }
          return null;
        case GateVerdict.accept:
          _pendingBorder = null;
      }
    } else {
      _pendingBorder = null;
    }
    // The fix is clearly inside `sampled`: close other timers now, at the
    // fix, not when the app next wakes (a left-behind county kept counting).
    await _closeOtherCandidates(except: sampled, at: at);
    if (previous == sampled) return null;

    if (previous != null) {
      await handleEvent(
        CountyCrossingEvent(
          countyCode: previous,
          kind: CrossingKind.exit,
          occurredAt: at,
        ),
      );
    }
    final beforeEnter = await currentCountyCode();
    await handleEvent(
      CountyCrossingEvent(
        countyCode: sampled,
        kind: CrossingKind.enter,
        occurredAt: at,
      ),
      fromFix: true,
    );
    final entered =
        await currentCountyCode() == sampled && beforeEnter != sampled;
    return entered ? sampled : null;
  }

  /// Applies one crossing. Returns the visit it resolved, if any.
  /// [fromFix]: a fix inside the county proved it (gate and transit passed),
  /// so the geofence-event speed sanity is skipped; it would compare the
  /// county against the one that same fix just closed.
  Future<ResolvedVisit?> handleEvent(
    CountyCrossingEvent event, {
    bool fromFix = false,
  }) async {
    await _ready;
    // A location-less geofence entry under a flight path says nothing about
    // where the phone is: ignore it while transit is in force.
    if (event.kind == CrossingKind.enter &&
        await transitFlag.activeAt(event.occurredAt)) {
      return null;
    }
    return _db.transaction(() async {
      await _ownerId();
      final existing = await (_db.select(
        _db.candidates,
      )..where((c) => c.countyCode.equals(event.countyCode))).getSingleOrNull();
      final decision = switch (event.kind) {
        CrossingKind.enter => rules.onEnter(
          existingCandidateEnteredAt: existing?.enteredAt,
          now: event.occurredAt,
        ),
        CrossingKind.exit => rules.onExit(
          candidateEnteredAt: existing?.enteredAt,
          now: event.occurredAt,
        ),
      };
      switch (decision.action) {
        case VisitAction.ignore:
          return null;
        case VisitAction.startCandidate:
          if (!fromFix &&
              !await _isPlausibleNewCandidate(
                event.countyCode,
                event.occurredAt,
              )) {
            return null;
          }
          await _db
              .into(_db.candidates)
              .insertOnConflictUpdate(
                CandidatesCompanion.insert(
                  countyCode: Value(event.countyCode),
                  enteredAt: decision.enteredAt!,
                ),
              );
          await _setCurrentCounty(event.countyCode);
          return null;
        case VisitAction.resolveExplored:
        case VisitAction.resolvePassedThrough:
          return _resolve(
            countyCode: event.countyCode,
            outcome: decision.action == VisitAction.resolveExplored
                ? VisitOutcome.explored
                : VisitOutcome.passedThrough,
            enteredAt: decision.enteredAt!,
            resolvedAt: event.occurredAt,
          );
      }
    });
  }

  /// Resolves every running candidate that has passed the dwell threshold
  /// (no platform reliably reports "still inside after 2 h").
  Future<List<ResolvedVisit>> checkStillActiveCandidates({
    DateTime? now,
  }) async {
    await _ownerId();
    final at = now ?? DateTime.now();
    final resolved = <ResolvedVisit>[];
    for (final candidate in await _db.select(_db.candidates).get()) {
      final decision = rules.checkStillCandidate(
        candidateEnteredAt: candidate.enteredAt,
        now: at,
      );
      if (decision.action != VisitAction.resolveExplored) continue;
      final visit = await _resolve(
        countyCode: candidate.countyCode,
        outcome: VisitOutcome.explored,
        enteredAt: decision.enteredAt!,
        resolvedAt: at,
      );
      if (visit != null) resolved.add(visit);
    }
    return resolved;
  }
}
