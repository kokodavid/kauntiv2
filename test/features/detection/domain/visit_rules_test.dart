import 'package:flutter_test/flutter_test.dart';
import 'package:kaunti47_v2/src/features/detection/domain/visit_models.dart';
import 'package:kaunti47_v2/src/features/detection/domain/visit_rules.dart';

void main() {
  const rules = VisitRules(VisitTimings.production);
  final t0 = DateTime.utc(2026, 9, 24, 8);

  group('timings', () {
    test('production: 2 h dwell, 2 min flap guard', () {
      expect(VisitTimings.production.dwellThreshold, const Duration(hours: 2));
      expect(VisitTimings.production.flapGuard, const Duration(minutes: 2));
    });

    test('dev: 2 min dwell, 15 s flap guard', () {
      expect(VisitTimings.dev.dwellThreshold, const Duration(minutes: 2));
      expect(VisitTimings.dev.flapGuard, const Duration(seconds: 15));
    });
  });

  group('enter', () {
    test('starts a candidate', () {
      final d = rules.onEnter(existingCandidateEnteredAt: null, now: t0);
      expect(d.action, VisitAction.startCandidate);
      expect(d.enteredAt, t0);
    });

    test('a duplicate enter keeps the original window', () {
      final d = rules.onEnter(existingCandidateEnteredAt: t0, now: t0);
      expect(d.action, VisitAction.ignore);
    });
  });

  group('exit', () {
    VisitDecision exitAfter(Duration dwell) =>
        rules.onExit(candidateEnteredAt: t0, now: t0.add(dwell));

    test('with no candidate is ignored', () {
      expect(
        rules.onExit(candidateEnteredAt: null, now: t0).action,
        VisitAction.ignore,
      );
    });

    test('inside the flap guard is ignored', () {
      expect(exitAfter(const Duration(seconds: 90)).action, VisitAction.ignore);
    });

    test('before the dwell threshold is passed through', () {
      final d = exitAfter(const Duration(minutes: 40));
      expect(d.action, VisitAction.resolvePassedThrough);
      expect(d.enteredAt, t0);
    });

    test('at the dwell threshold is explored', () {
      expect(
        exitAfter(const Duration(hours: 2)).action,
        VisitAction.resolveExplored,
      );
    });
  });

  test('a long-running candidate resolves as explored', () {
    expect(
      rules
          .checkStillCandidate(
            candidateEnteredAt: t0,
            now: t0.add(const Duration(minutes: 119)),
          )
          .action,
      VisitAction.ignore,
    );
    expect(
      rules
          .checkStillCandidate(
            candidateEnteredAt: t0,
            now: t0.add(const Duration(hours: 3)),
          )
          .action,
      VisitAction.resolveExplored,
    );
  });

  test('speed sanity rejects impossible jumps only', () {
    expect(
      VisitRules.isPlausibleTransition(
        distanceMeters: 100000,
        elapsed: const Duration(hours: 1),
      ),
      isTrue,
    );
    expect(
      VisitRules.isPlausibleTransition(
        distanceMeters: 300000,
        elapsed: const Duration(minutes: 10),
      ),
      isFalse,
    );
    expect(
      VisitRules.isPlausibleTransition(
        distanceMeters: 200,
        elapsed: Duration.zero,
      ),
      isTrue,
    );
  });

  test('outcomes round-trip their wire names', () {
    for (final outcome in VisitOutcome.values) {
      expect(VisitOutcome.fromWire(outcome.wireName), outcome);
    }
    expect(VisitOutcome.explored.wireName, 'explored');
    expect(VisitOutcome.passedThrough.wireName, 'passed_through');
  });
}
