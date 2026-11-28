import 'package:flutter_test/flutter_test.dart';
import 'package:kaunti47_v2/src/features/detection/domain/pending_claim.dart';
import 'package:kaunti47_v2/src/features/detection/domain/visit_models.dart';

void main() {
  const dwell = Duration(hours: 2);
  final t0 = DateTime.utc(2026, 11, 27, 10);

  test('soonest picks the earliest claim', () {
    final claim = PendingClaim.soonest([
      CountyArrivalNudge(
        countyCode: 1,
        enteredAt: t0.add(const Duration(minutes: 30)),
      ),
      CountyArrivalNudge(countyCode: 2, enteredAt: t0),
    ], dwell);
    expect(claim?.countyCode, 2);
    expect(claim?.claimsAt, t0.add(dwell));
  });

  test('none pending gives null', () {
    expect(PendingClaim.soonest(const [], dwell), isNull);
  });

  test('timeLeft formats and rounds up', () {
    expect(
      PendingClaim.timeLeft(const Duration(hours: 1, minutes: 20)),
      '1 h 20 m',
    );
    expect(PendingClaim.timeLeft(const Duration(hours: 2)), '2 h');
    expect(
      PendingClaim.timeLeft(const Duration(minutes: 44, seconds: 10)),
      '45 m',
    );
    expect(
      PendingClaim.timeLeft(const Duration(seconds: 20)),
      'under a minute',
    );
    expect(PendingClaim.timeLeft(Duration.zero), 'any moment');
  });
}
