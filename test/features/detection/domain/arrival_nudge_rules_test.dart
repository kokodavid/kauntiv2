import 'package:flutter_test/flutter_test.dart';
import 'package:kaunti47_v2/src/features/detection/domain/arrival_nudge_rules.dart';
import 'package:kaunti47_v2/src/features/detection/domain/visit_models.dart';

void main() {
  final t0 = DateTime.utc(2026, 9, 24, 8);
  final kiambu = CountyArrivalNudge(countyCode: 22, enteredAt: t0);
  final nairobi = CountyArrivalNudge(
    countyCode: 47,
    enteredAt: t0.add(const Duration(minutes: 30)),
  );

  test('picks the newest crossing', () {
    expect(ArrivalNudgeRules.pick([nairobi, kiambu]), nairobi);
    expect(ArrivalNudgeRules.pick([kiambu, nairobi]), nairobi);
  });

  test('never the home county', () {
    expect(ArrivalNudgeRules.pick([nairobi], suppressed: {47}), isNull);
    expect(
      ArrivalNudgeRules.pick([kiambu, nairobi], suppressed: {47}),
      kiambu,
    );
  });

  test('a crossing that already showed is skipped', () {
    final shown = {ArrivalNudgeRules.keyFor(47, nairobi.enteredAt)};
    expect(ArrivalNudgeRules.pick([nairobi], shown: shown), isNull);
    // A later crossing into the same county is a new one.
    final again = CountyArrivalNudge(
      countyCode: 47,
      enteredAt: t0.add(const Duration(days: 1)),
    );
    expect(ArrivalNudgeRules.pick([again], shown: shown), again);
  });

  test('keys use v1 format in UTC', () {
    expect(
      ArrivalNudgeRules.keyFor(47, DateTime.utc(2026, 9, 24, 8)),
      '47@2026-09-24T08:00:00.000Z',
    );
  });
}
