import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:kaunti47_v2/src/features/public_trips/domain/public_trip_moment_kind.dart';
import 'package:kaunti47_v2/src/features/public_trips/domain/public_trip_request_id.dart';
import 'package:kaunti47_v2/src/features/public_trips/domain/public_trip_share_preferences.dart';

void main() {
  test('defaults show places but nothing about the person', () {
    const prefs = PublicTripSharePreferences.defaults;
    expect(prefs.includes(PublicTripMomentKind.countyCrossing), isTrue);
    expect(prefs.includes(PublicTripMomentKind.elevationPeak), isTrue);
    expect(prefs.includes(PublicTripMomentKind.topSpeed), isFalse);
    expect(prefs.includes(PublicTripMomentKind.longStop), isFalse);
    expect(prefs.includes(PublicTripMomentKind.recordingBreak), isFalse);
    expect(prefs.photos, isFalse);
    expect(prefs.trimMeters, 500);
  });

  test('withKind changes only that kind', () {
    final next = PublicTripSharePreferences.defaults.withKind(
      PublicTripMomentKind.topSpeed,
      true,
    );
    expect(next.topSpeed, isTrue);
    expect(next.countyCrossing, isTrue);
    expect(next.longStop, isFalse);
  });

  test('reads the server JSON and falls back to defaults', () {
    final prefs = PublicTripSharePreferences.fromJson({
      'top_speed': true,
      'trim_m': 2000,
    });
    expect(prefs.topSpeed, isTrue);
    expect(prefs.trimMeters, 2000);
    expect(prefs.countyCrossing, isTrue);
  });

  test('sensitive kinds carry a hint, places do not', () {
    expect(PublicTripMomentKind.topSpeed.isSensitive, isTrue);
    expect(PublicTripMomentKind.countyCrossing.isSensitive, isFalse);
  });

  test('request ids look like version 4 UUIDs and differ', () {
    final a = newPublicTripRequestId(Random(1));
    final b = newPublicTripRequestId(Random(2));
    final pattern = RegExp(
      r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
    );
    expect(a, matches(pattern));
    expect(b, matches(pattern));
    expect(a, isNot(b));
  });
}
