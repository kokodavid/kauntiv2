import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/services/app_current_location.dart';
import '../domain/check_in_outcome.dart';

/// Checking in at a place: read one position, let the server decide.
abstract interface class PlaceCheckInRepository {
  Future<PlaceCheckInStatus> status(String placeId);

  Future<CheckInOutcome> checkIn(String placeId);
}

class SupabasePlaceCheckInRepository implements PlaceCheckInRepository {
  const SupabasePlaceCheckInRepository(
    this._client, {
    Future<AppLocationReading?> Function()? readLocation,
    DateTime Function()? now,
  }) : _readLocation = readLocation ?? AppCurrentLocation.readDetailed,
       _now = now ?? DateTime.now;

  final SupabaseClient _client;
  final Future<AppLocationReading?> Function() _readLocation;
  final DateTime Function() _now;

  static const _timeout = Duration(seconds: 12);

  /// A fix older than this is the phone's last known position, not where
  /// the person is now.
  static const maxFixAge = Duration(minutes: 2);

  @override
  Future<PlaceCheckInStatus> status(String placeId) async {
    final flag = await _client
        .from('app_feature_flags')
        .select('enabled')
        .eq('feature_key', 'place_check_ins')
        .maybeSingle()
        .timeout(_timeout);
    if (flag?['enabled'] != true) return const PlaceCheckInStatus();
    final rows = await _client
        .from('place_check_ins')
        .select('visit_day')
        .eq('place_id', placeId)
        .timeout(_timeout);
    final days = [
      for (final row in rows)
        if (row['visit_day'] case final String day) day,
    ];
    final now = _now().toUtc().add(const Duration(hours: 3));
    final today =
        '${now.year.toString().padLeft(4, '0')}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';
    return PlaceCheckInStatus(
      enabled: true,
      checkedInToday: days.contains(today),
      visits: days.toSet().length,
    );
  }

  @override
  Future<CheckInOutcome> checkIn(String placeId) async {
    final fix = await _readLocation();
    if (fix == null) {
      return const CheckInOutcome.failed(CheckInFailure.noLocation);
    }
    final takenAt = fix.takenAt;
    if (takenAt != null && _now().difference(takenAt) > maxFixAge) {
      return const CheckInOutcome.failed(CheckInFailure.lowAccuracy);
    }
    final accuracy = fix.accuracyMeters;
    if (accuracy == null) {
      return const CheckInOutcome.failed(CheckInFailure.lowAccuracy);
    }
    final Map<String, dynamic> row;
    try {
      row = await _client
          .rpc<Map<String, dynamic>>(
            'check_in_to_place',
            params: {
              'p_place_id': placeId,
              'p_lat': fix.latitude,
              'p_lng': fix.longitude,
              'p_accuracy_m': accuracy,
            },
          )
          .timeout(_timeout);
    } on PostgrestException catch (error) {
      if (error.message == 'feature_off') {
        return const CheckInOutcome.failed(CheckInFailure.paused);
      }
      rethrow;
    }
    int? n(String key) => (row[key] as num?)?.toInt();
    if (row['ok'] == true) {
      return CheckInOutcome.counted(
        already: row['already'] == true,
        distanceMeters: n('distance_m'),
        radiusMeters: n('radius_m'),
      );
    }
    final failure = switch (row['reason']) {
      'too_far' => CheckInFailure.tooFar,
      'low_accuracy' => CheckInFailure.lowAccuracy,
      'daily_limit' => CheckInFailure.dailyLimit,
      _ => CheckInFailure.placeUnavailable,
    };
    return CheckInOutcome.failed(
      failure,
      distanceMeters: n('distance_m'),
      radiusMeters: n('radius_m'),
    );
  }
}
