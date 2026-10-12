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
    expect(ArrivalNudgeRules.pick([kiambu, nairobi], suppressed: {47}), kiambu);
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

  test('a county shown within the cooldown stays quiet on re-entry', () {
    final now = t0.add(const Duration(days: 3));
    final again = CountyArrivalNudge(
      countyCode: 47,
      enteredAt: now.subtract(const Duration(minutes: 5)),
    );
    final lastShown = {47: t0};
    expect(
      ArrivalNudgeRules.pick([again], lastShown: lastShown, now: now),
      isNull,
    );
    // Another county is unaffected.
    expect(
      ArrivalNudgeRules.pick([again, kiambu], lastShown: lastShown, now: now),
      kiambu,
    );
  });

  test('after the cooldown a county can show again', () {
    final now = t0.add(ArrivalNudgeRules.revisitCooldown);
    final again = CountyArrivalNudge(countyCode: 47, enteredAt: now);
    expect(
      ArrivalNudgeRules.pick([again], lastShown: {47: t0}, now: now),
      again,
    );
  });
}
