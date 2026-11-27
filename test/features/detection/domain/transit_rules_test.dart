import 'package:flutter_test/flutter_test.dart';
import 'package:kaunti47_v2/src/features/detection/domain/transit_rules.dart';

void main() {
  const rules = TransitRules();
  final t0 = DateTime.utc(2026, 11, 27, 8);

  bool transit({
    required double toLat,
    required double toLng,
    required Duration after,
  }) => rules.isTransit(
    fromLatitude: -1.292629,
    fromLongitude: 36.864399,
    fromAt: t0,
    toLatitude: toLat,
    toLongitude: toLng,
    toAt: t0.add(after),
  );

  test('a flight to Kisumu (about 270 km in an hour) is transit', () {
    expect(
      transit(toLat: -0.0861, toLng: 34.7289, after: const Duration(hours: 1)),
      isTrue,
    );
  });

  test('a road trip to Nakuru (about 140 km in 2.5 h) is not', () {
    expect(
      transit(
        toLat: -0.3031,
        toLng: 36.0800,
        after: const Duration(hours: 2, minutes: 30),
      ),
      isFalse,
    );
  });

  test('fixes seconds apart are not judged', () {
    expect(
      transit(
        toLat: -0.0861,
        toLng: 34.7289,
        after: const Duration(seconds: 5),
      ),
      isFalse,
    );
  });

  test('the speed limit is configurable', () {
    const slow = TransitRules(TransitConfig(speedKmh: 50));
    expect(
      slow.isTransit(
        fromLatitude: -1.292629,
        fromLongitude: 36.864399,
        fromAt: t0,
        toLatitude: -0.3031,
        toLongitude: 36.0800,
        toAt: t0.add(const Duration(hours: 2, minutes: 30)),
      ),
      isTrue,
    );
  });
}
