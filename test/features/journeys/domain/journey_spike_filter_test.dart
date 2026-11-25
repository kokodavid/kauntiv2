import 'package:flutter_test/flutter_test.dart';
import 'package:kaunti47_v2/src/features/journeys/domain/journey_fix.dart';
import 'package:kaunti47_v2/src/features/journeys/domain/journey_spike_filter.dart';

void main() {
  final t0 = DateTime.utc(2026, 11, 13, 9);

  // About 0.0001 degrees of latitude is 11 m.
  JourneyFix fix(int seconds, double metresNorth) => JourneyFix(
    recordedAt: t0.add(Duration(seconds: seconds)),
    latitude: -1.28 + metresNorth / 111000,
    longitude: 36.82,
    accuracyMeters: 8,
  );

  // A walker: 4 m/s is the limit.
  JourneySpikeFilter walker() => JourneySpikeFilter(maxSpeedMetersPerSecond: 4);

  test('ordinary fixes are accepted straight away', () {
    final filter = walker();
    expect(filter.judge(fix(0, 0)).accepted, hasLength(1));
    final next = filter.judge(fix(10, 15));
    expect(next.accepted, hasLength(1));
    expect(next.held, isFalse);
    expect(next.spikesDropped, 0);
  });

  test('a single spike is held, then dropped by the next fix', () {
    final filter = walker();
    filter.judge(fix(0, 0));
    filter.judge(fix(10, 15));

    final spike = filter.judge(fix(20, 600));
    expect(spike.accepted, isEmpty);
    expect(spike.held, isTrue);

    final back = filter.judge(fix(30, 45));
    expect(back.accepted, hasLength(1));
    expect(back.spikesDropped, 1);
    expect(back.startsNewSegment, isFalse);
    expect(filter.isHolding, isFalse);
  });

  test('a real jump is accepted once the next fix confirms it', () {
    final filter = walker();
    filter.judge(fix(0, 0));
    filter.judge(fix(10, 15));

    final first = filter.judge(fix(20, 2000));
    expect(first.accepted, isEmpty);

    final confirm = filter.judge(fix(30, 2020));
    expect(confirm.accepted, hasLength(2));
    expect(
      confirm.accepted.first.recordedAt,
      t0.add(const Duration(seconds: 20)),
    );
    expect(confirm.startsNewSegment, isTrue);
    expect(confirm.spikesDropped, 0);

    final after = filter.judge(fix(40, 2035));
    expect(after.accepted, hasLength(1));
    expect(after.startsNewSegment, isFalse);
  });

  test('two fixes that agree with nothing replace the held one', () {
    final filter = walker();
    filter.judge(fix(0, 0));

    expect(filter.judge(fix(10, 900)).held, isTrue);
    final second = filter.judge(fix(20, -1200));
    expect(second.accepted, isEmpty);
    expect(second.spikesDropped, 1);
    expect(second.held, isTrue);

    final back = filter.judge(fix(30, 20));
    expect(back.accepted, hasLength(1));
    expect(back.spikesDropped, 1);
  });

  test('a Trip with no mode accepts every fix', () {
    final filter = JourneySpikeFilter(maxSpeedMetersPerSecond: null);
    filter.judge(fix(0, 0));
    final far = filter.judge(fix(1, 50000));
    expect(far.accepted, hasLength(1));
    expect(far.held, isFalse);
  });

  test('a fix that is not newer than the route is ignored', () {
    final filter = walker();
    filter.judge(fix(10, 0));
    final old = filter.judge(fix(5, 5));
    expect(old.accepted, isEmpty);
    expect(old.held, isFalse);
  });

  test('reset forgets the route', () {
    final filter = walker();
    filter.judge(fix(0, 0));
    filter.judge(fix(10, 900));
    expect(filter.isHolding, isTrue);
    filter.reset();
    expect(filter.isHolding, isFalse);
    expect(filter.judge(fix(20, 5000)).accepted, hasLength(1));
  });
}
