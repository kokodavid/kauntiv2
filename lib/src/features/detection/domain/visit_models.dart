/// A raw signal from the OS: the phone crossed a registered geofence
/// boundary. The geofence layer emits these; [VisitRules] turns them into
/// doc 01's visit-state transitions.
enum CrossingKind { enter, exit }

class CountyCrossingEvent {
  const CountyCrossingEvent({
    required this.countyCode,
    required this.kind,
    required this.occurredAt,
  });

  final int countyCode;
  final CrossingKind kind;
  final DateTime occurredAt;

  @override
  String toString() =>
      'CountyCrossingEvent(county: $countyCode, kind: $kind, at: $occurredAt)';
}

/// Doc 01's two outcomes for a resolved visit. "Pending" isn't a third
/// outcome: it's the sync status of a resolved visit not yet uploaded.
enum VisitOutcome {
  explored('explored'),
  passedThrough('passed_through');

  const VisitOutcome(this.wireName);

  /// The value `sync_county_visit` and the local queue store.
  final String wireName;

  static VisitOutcome fromWire(String value) =>
      value == 'explored' ? explored : passedThrough;
}

/// One resolved, ready-to-sync visit.
class ResolvedVisit {
  const ResolvedVisit({
    required this.countyCode,
    required this.outcome,
    required this.enteredAt,
    required this.resolvedAt,
  });

  final int countyCode;
  final VisitOutcome outcome;
  final DateTime enteredAt;
  final DateTime resolvedAt;

  @override
  String toString() =>
      'ResolvedVisit(county: $countyCode, outcome: $outcome, '
      'entered: $enteredAt, resolved: $resolvedAt)';
}

/// A county crossing worth telling the user about (the arrival sheet).
/// Based on the candidate ENTER, before dwell decides the outcome, so Home
/// can say "you crossed into X" right away.
class CountyArrivalNudge {
  const CountyArrivalNudge({required this.countyCode, required this.enteredAt});

  final int countyCode;
  final DateTime enteredAt;
}
