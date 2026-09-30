import 'dart:isolate';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/domain/map_place.dart';
import '../domain/journey_destination.dart';
import '../domain/journey_moments.dart';
import '../domain/journey_point.dart';
import '../domain/journey_summary.dart';
import '../domain/pro_status.dart';
import 'journey_county_split_resolver.dart';
import 'journey_place_thumbnail.dart';

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
    Duration pausedDuration = Duration.zero,
    JourneyDestination? destination,
  }) async {
    // County lookups over a long route are real work: off the UI isolate.
    final counties = await Isolate.run(() => splitJourneyCounties(points));
    final result = await _client
        .rpc<Map<String, dynamic>>(
          destination == null ? 'upload_journey' : 'upload_journey_to_place',
          params: {
            'p_user_id': userId,
            'p_journey_id': id,
            'p_title': title,
            'p_started_at': startedAt.toUtc().toIso8601String(),
            'p_ended_at': endedAt.toUtc().toIso8601String(),
            'p_paused_ms': pausedDuration.inMilliseconds,
            'p_counties': [
              for (final MapEntry(key: code, value: meters) in counties.entries)
                {
                  'county_id': code,
                  'distance_m': double.parse(meters.toStringAsFixed(2)),
                },
            ],
            'p_points': [
              for (final point in points)
                {
                  'segment': point.segmentNumber,
                  'recorded_at': point.recordedAt.toUtc().toIso8601String(),
                  'lat': point.latitude,
                  'lng': point.longitude,
                  'accuracy_m': point.accuracyMeters,
                  'altitude_m': point.altitudeMeters,
                  'speed_mps': point.speedMetersPerSecond,
                },
            ],
            if (destination != null) ...{
              'p_destination_place_id': destination.placeId,
              'p_destination_name': destination.name,
              'p_destination_latitude': destination.latitude,
              'p_destination_longitude': destination.longitude,
            },
          },
        )
        .timeout(_uploadTimeout);
    return (result['distance_m'] as num).toDouble();
  }

  Future<List<JourneySummary>> history() async {
    final rows = await readAllPages(
      (from, to) => _client
          .from('journeys')
          .select(
            'id, title, started_at, ended_at, distance_m, paused_ms, '
            'destination_place_id, destination_name, '
            'destination_latitude, destination_longitude, '
            'top_speed_mps, highest_elevation_m',
          )
          .order('started_at', ascending: false)
          // postgrest-dart's order() is descending unless told otherwise.
          .order('id', ascending: true)
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
    pausedDuration: Duration(
      milliseconds: (row['paused_ms'] as num?)?.toInt() ?? 0,
    ),
    isUploaded: true,
    destination: row['destination_place_id'] == null
        ? null
        : JourneyDestination(
            placeId: row['destination_place_id'] as String,
            name: row['destination_name'] as String,
            latitude: (row['destination_latitude'] as num?)?.toDouble(),
            longitude: (row['destination_longitude'] as num?)?.toDouble(),
          ),
    topSpeedMps: (row['top_speed_mps'] as num?)?.toDouble(),
    highestElevationMeters: (row['highest_elevation_m'] as num?)?.toDouble(),
  );

  /// One uploaded Journey, or null if it's gone (deleted elsewhere).
  Future<JourneySummary?> journey(String id) async {
    final row = await _client
        .from('journeys')
        .select(
          'id, title, started_at, ended_at, distance_m, paused_ms, '
          'destination_place_id, destination_name, '
          'destination_latitude, destination_longitude, '
          'top_speed_mps, highest_elevation_m',
        )
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
            'segment_number, recorded_at, latitude, longitude, accuracy_m, '
            'altitude_m, speed_mps',
          )
          .eq('journey_id', journeyId)
          // Recording order. order() defaults to descending, which
          // replayed the route backwards.
          .order('sequence_number', ascending: true)
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
          altitudeMeters: (row['altitude_m'] as num?)?.toDouble(),
          speedMetersPerSecond: (row['speed_mps'] as num?)?.toDouble(),
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

  /// Renames [userId]'s Journey. The server rejects it unless [userId] is
  /// still the signed-in account (no client update policy on `journeys`;
  /// `rename_journey` is the only write path).
  Future<void> rename({
    required String userId,
    required String id,
    required String title,
  }) => _client
      .rpc<Object?>(
        'rename_journey',
        params: {'p_user_id': userId, 'p_journey_id': id, 'p_title': title},
      )
      .timeout(_timeout);

  /// Every place with coordinates, marked saved when on [userId]'s list,
  /// for the places near a replayed route.
  Future<List<JourneyPlaceMark>> places(String userId) async {
    final results = await Future.wait([
      readAllPages(
        (from, to) => _client
            .from('places')
            .select(
              'id, county_id, name, type, summary, lat, lng, '
              'place_images(thumbnail_url, sort_order)',
            )
            .not('lat', 'is', null)
            .order('id', ascending: true)
            .range(from, to)
            .timeout(_timeout),
      ),
      _client
          .from('wishlist_items')
          .select('place_id')
          .eq('user_id', userId)
          .timeout(_timeout),
    ]);
    final saved = {for (final row in results[1]) row['place_id']};
    return [
      for (final row in results[0])
        if (row case {
          'id': final String id,
          'county_id': final int county,
          'name': final String name,
          'lat': final num lat,
          'lng': final num lng,
        })
          JourneyPlaceMark(
            id: id,
            countyCode: county,
            name: name,
            latitude: lat.toDouble(),
            longitude: lng.toDouble(),
            saved: saved.contains(id),
            categoryLabel: row['type'] as String?,
            description: row['summary'] as String?,
            thumbnailUrl: journeyPlaceThumbnail(row['place_images']),
          ),
    ];
  }

  /// Every place with coordinates, as map pins (same as Home's map), for
  /// the map while recording.
  Future<List<MapPlace>> mapPlaces() async {
    final rows = await readAllPages(
      (from, to) => _client
          .from('places')
          .select(
            'id, name, type, summary, county_id, lat, lng, '
            'place_images(thumbnail_url, sort_order)',
          )
          .not('lat', 'is', null)
          .order('id', ascending: true)
          .range(from, to)
          .timeout(_timeout),
    );
    return [
      for (final row in rows)
        if (row['lat'] is num && row['lng'] is num)
          MapPlace(
            id: row['id'] as String,
            name: row['name'] as String,
            type: row['type'] as String,
            countyCode: (row['county_id'] as num).toInt(),
            lat: (row['lat'] as num).toDouble(),
            lng: (row['lng'] as num).toDouble(),
            summary: row['summary'] as String?,
            thumbnailUrl: journeyPlaceThumbnail(row['place_images']),
          ),
    ];
  }
}
