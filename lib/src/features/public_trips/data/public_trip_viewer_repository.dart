import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/public_trip_failure.dart';
import '../domain/public_trip_report_reason.dart';
import '../domain/public_trip_view.dart';

/// What other people can do with public trips: browse, open, report, block.
abstract interface class PublicTripViewerRepository {
  /// Whether public trips are switched on for viewers right now.
  Future<bool> readingEnabled();

  /// Trips near [countyCode] ranked by how many of their counties the
  /// viewer has not explored.
  Future<List<PublicTripView>> forYou(int countyCode, {int limit = 10});

  /// One live trip, or null when it is unavailable to this viewer (withdrawn,
  /// hidden, blocked or never approved). The reasons are not distinguished.
  Future<PublicTripView?> get(String publicationId);

  /// Short-lived links for the trip's photos, keyed by photo ID. A photo
  /// whose link cannot be made is left out.
  Future<Map<String, String>> photoUrls(PublicTripView trip);

  Future<void> report({
    required String publicationId,
    required PublicTripReportReason reason,
    String? details,
  });

  Future<void> setAuthorBlocked(String authorId, {required bool blocked});
}

class SupabasePublicTripViewerRepository implements PublicTripViewerRepository {
  const SupabasePublicTripViewerRepository(this.client);

  final SupabaseClient client;

  static const _timeout = Duration(seconds: 20);
  static const _bucket = 'public-trip-media';

  /// Long enough to look at a trip, short enough that a withdrawn trip's
  /// photos stop loading soon.
  static const _linkLifetimeSeconds = 600;

  @override
  Future<bool> readingEnabled() async {
    try {
      final row = await client
          .from('app_feature_flags')
          .select('enabled')
          .eq('feature_key', 'public_trips_read')
          .maybeSingle()
          .timeout(_timeout);
      return row?['enabled'] == true;
    } on Object {
      return false;
    }
  }

  @override
  Future<List<PublicTripView>> forYou(int countyCode, {int limit = 10}) async {
    final result = await _rpc('public_trips_for_you', {
      'p_county_code': countyCode,
      'p_limit': limit,
    });
    if (result is! List<dynamic>) return const [];
    return [
      for (final item in result)
        PublicTripView.fromJson(item as Map<String, dynamic>),
    ];
  }

  @override
  Future<PublicTripView?> get(String publicationId) async {
    final result = await _rpc('get_public_trip', {
      'p_publication_id': publicationId,
    });
    return result is Map<String, dynamic>
        ? PublicTripView.fromJson(result)
        : null;
  }

  @override
  Future<Map<String, String>> photoUrls(PublicTripView trip) async {
    if (trip.photos.isEmpty) return const {};
    // The worker stores each sanitized copy at this path.
    String pathOf(String photoId) => '${trip.id}/${trip.revision}/$photoId.jpg';
    // One link per photo (at most ten); a photo whose link fails is left out.
    Future<MapEntry<String, String>?> sign(PublicTripPhoto photo) async {
      try {
        final url = await client.storage
            .from(_bucket)
            .createSignedUrl(pathOf(photo.id), _linkLifetimeSeconds)
            .timeout(_timeout);
        return MapEntry(photo.id, url);
      } on Object {
        return null;
      }
    }

    final signed = await Future.wait(trip.photos.map(sign));
    return {
      for (final entry in signed)
        if (entry != null) entry.key: entry.value,
    };
  }

  @override
  Future<void> report({
    required String publicationId,
    required PublicTripReportReason reason,
    String? details,
  }) async {
    final trimmed = details?.trim();
    await _rpc('report_public_trip', {
      'p_publication_id': publicationId,
      'p_reason': reason.wire,
      'p_details': trimmed == null || trimmed.isEmpty ? null : trimmed,
    });
  }

  @override
  Future<void> setAuthorBlocked(
    String authorId, {
    required bool blocked,
  }) async {
    await _rpc('block_public_trip_author', {
      'p_author_id': authorId,
      'p_blocked': blocked,
    });
  }

  Future<dynamic> _rpc(String name, Map<String, dynamic> params) async {
    try {
      return await client.rpc<dynamic>(name, params: params).timeout(_timeout);
    } on PostgrestException catch (error) {
      throw PublicTripFailure(_friendly(error));
    } on Object {
      throw const PublicTripFailure(
        'Could not reach Kaunti47. Check your connection and try again.',
      );
    }
  }

  static String _friendly(PostgrestException error) {
    final message = error.message;
    if (message == 'Public trips unavailable') {
      return 'Public trips are not available right now.';
    }
    if (error.code == '54000') {
      return 'You have done that too many times. Try again later.';
    }
    return message.isEmpty ? 'The request was refused.' : message;
  }
}
