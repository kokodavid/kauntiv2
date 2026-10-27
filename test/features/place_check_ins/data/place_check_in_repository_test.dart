import 'package:flutter_test/flutter_test.dart';
import 'package:kaunti47_v2/src/core/services/app_current_location.dart';
import 'package:kaunti47_v2/src/features/place_check_ins/data/place_check_in_repository.dart';
import 'package:kaunti47_v2/src/features/place_check_ins/domain/check_in_outcome.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Only the decisions made before the server is asked: no position, an old
/// fix, a loose fix. The distance rule lives in SQL.
void main() {
  final now = DateTime(2026, 10, 20, 12);
  final client = SupabaseClient('http://localhost', 'anon');

  SupabasePlaceCheckInRepository repo(
    Future<AppLocationReading?> Function() read,
  ) => SupabasePlaceCheckInRepository(
    client,
    readLocation: read,
    now: () => now,
  );

  test('no position means noLocation', () async {
    final outcome = await repo(() async => null).checkIn('p');
    expect(outcome.failure, CheckInFailure.noLocation);
  });

  test('a fix older than two minutes is refused', () async {
    final outcome = await repo(
      () async => (
        latitude: -1.0,
        longitude: 36.0,
        accuracyMeters: 10.0,
        takenAt: now.subtract(const Duration(minutes: 5)),
      ),
    ).checkIn('p');
    expect(outcome.failure, CheckInFailure.lowAccuracy);
  });

  test('a fix with no accuracy is refused', () async {
    final outcome = await repo(
      () async =>
          (latitude: -1.0, longitude: 36.0, accuracyMeters: null, takenAt: now),
    ).checkIn('p');
    expect(outcome.failure, CheckInFailure.lowAccuracy);
  });
}
