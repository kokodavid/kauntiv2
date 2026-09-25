import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/journey_point.dart';
import '../domain/journey_summary.dart';
import '../domain/pro_status.dart';

/// Journeys in the cloud: the Pro check, the one upload RPC, and private
/// history reads and deletion (RLS keeps every read to the owner).
class SupabaseJourneyRepository {
  const SupabaseJourneyRepository(this._client);

  final SupabaseClient _client;

  static const _timeout = Duration(seconds: 8);

  /// Longer: a long Journey is a big payload.
  static const _uploadTimeout = Duration(seconds: 30);

  String? get currentUserId => _client.auth.currentUser?.id;

  Future<ProStatus> proStatus() async {
    final row = await _client
        .rpc<Map<String, dynamic>>('my_pro_status')
        .timeout(_timeout);
    final until = row['active_until'] as String?;
    return ProStatus(
      active: row['active'] == true,
      activeUntil: until == null ? null : DateTime.parse(until),
      checkedAt: DateTime.parse(row['checked_at'] as String),
    );
  }

  /// Supabase caps a read at 1,000 rows by default; reads page through.
  static const pageSize = 1000;

  /// Uploads [userId]'s completed Journey; returns the server's distance in
  /// metres. The server rejects it unless [userId] is still the signed-in
  /// account. Idempotent: a retry after a lost response returns the stored
  /// one.
  Future<double> upload({
    required String userId,
    required String id,
    required String title,
    required DateTime startedAt,
    required DateTime endedAt,
    required List<JourneyPoint> points,
  }) async {
    final result = await _client
        .rpc<Map<String, dynamic>>(
          'upload_journey',
          params: {
            'p_user_id': userId,
            'p_journey_id': id,
            'p_title': title,
            'p_started_at': startedAt.toUtc().toIso8601String(),
            'p_ended_at': endedAt.toUtc().toIso8601String(),
            'p_points': [
              for (final point in points)
                {
                  'segment': point.segmentNumber,
                  'recorded_at': point.recordedAt.toUtc().toIso8601String(),
                  'lat': point.latitude,
                  'lng': point.longitude,
                  'accuracy_m': point.accuracyMeters,
                },
            ],
          },
        )
        .timeout(_uploadTimeout);
    return (result['distance_m'] as num).toDouble();
  }

  Future<List<JourneySummary>> history() async {
    final rows = await readAllPages(
      (from, to) => _client
          .from('journeys')
          .select('id, title, started_at, ended_at, distance_m')
          .order('started_at', ascending: false)
          .order('id')
          .range(from, to)
          .timeout(_timeout),
    );
    return [for (final row in rows) _summary(row)];
  }

  static JourneySummary _summary(Map<String, dynamic> row) => JourneySummary(
    id: row['id'] as String,
    title: row['title'] as String,
    startedAt: DateTime.parse(row['started_at'] as String),
    endedAt: DateTime.parse(row['ended_at'] as String),
    distanceMeters: (row['distance_m'] as num).toDouble(),
    isUploaded: true,
  );

  /// One uploaded Journey, or null if it's gone (deleted elsewhere).
  Future<JourneySummary?> journey(String id) async {
    final row = await _client
        .from('journeys')
        .select('id, title, started_at, ended_at, distance_m')
        .eq('id', id)
        .maybeSingle()
        .timeout(_timeout);
    return row == null ? null : _summary(row);
  }

  Future<List<JourneyPoint>> points(String journeyId) async {
    final rows = await readAllPages(
      (from, to) => _client
          .from('journey_points')
          .select(
            'segment_number, recorded_at, latitude, longitude, accuracy_m',
          )
          .eq('journey_id', journeyId)
          .order('sequence_number')
          .range(from, to)
          .timeout(_timeout),
    );
    return [
      for (final row in rows)
        JourneyPoint(
          recordedAt: DateTime.parse(row['recorded_at'] as String),
          latitude: (row['latitude'] as num).toDouble(),
          longitude: (row['longitude'] as num).toDouble(),
          accuracyMeters: (row['accuracy_m'] as num).toDouble(),
          segmentNumber: row['segment_number'] as int,
        ),
    ];
  }

  /// Reads every page of a query ordered on a unique key, [pageSize] rows
  /// at a time, until a short page.
  static Future<List<Map<String, dynamic>>> readAllPages(
    Future<List<Map<String, dynamic>>> Function(int from, int to) page,
  ) async {
    final rows = <Map<String, dynamic>>[];
    while (true) {
      final next = await page(rows.length, rows.length + pageSize - 1);
      rows.addAll(next);
      if (next.length < pageSize) return rows;
    }
  }

  /// Deletes the Journey and (by cascade) its points.
  Future<void> delete(String journeyId) =>
      _client.from('journeys').delete().eq('id', journeyId).timeout(_timeout);
}
