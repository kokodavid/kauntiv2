import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/public_trip_failure.dart';
import '../domain/public_trip_owner_view.dart';
import '../domain/public_trip_share_preferences.dart';

/// A moment the owner chose: its kind and the recorded point it sits at.
typedef PublicTripMomentChoice = ({String kind, int sequenceNumber});

/// The terms the owner accepts when submitting. The server rejects any other
/// value, so a stale app cannot submit under old terms.
const publicTripTermsVersion = 'public-trips-v1';

abstract interface class PublicTripRepository {
  /// Whether submitting public trips is switched on right now.
  Future<bool> publishingEnabled();

  /// The latest revision of this trip's public copy, or null if none.
  Future<PublicTripOwnerView?> mine(String journeyId);

  /// Builds (or returns the same) sanitized preview for these choices.
  Future<PublicTripOwnerView> prepare({
    required String journeyId,
    required String requestId,
    required String title,
    required List<PublicTripMomentChoice> moments,
    required List<String> photoIds,
    required int startTrimMeters,
    required int endTrimMeters,
  });

  Future<PublicTripOwnerView> submit({
    required String publicationId,
    required int revision,
    required String contentHash,
  });

  Future<void> withdraw({
    required String publicationId,
    required String requestId,
  });

  Future<PublicTripSharePreferences> sharePreferences();

  Future<PublicTripSharePreferences> saveSharePreferences(
    PublicTripSharePreferences preferences,
  );
}

class SupabasePublicTripRepository implements PublicTripRepository {
  const SupabasePublicTripRepository(this.client);

  final SupabaseClient client;

  static const _timeout = Duration(seconds: 20);

  @override
  Future<bool> publishingEnabled() async {
    try {
      final row = await client
          .from('app_feature_flags')
          .select('enabled')
          .eq('feature_key', 'public_trips_publish')
          .maybeSingle()
          .timeout(_timeout);
      return row?['enabled'] == true;
    } on Object {
      // Unknown means off: never offer something that might be refused.
      return false;
    }
  }

  @override
  Future<PublicTripOwnerView?> mine(String journeyId) async {
    final json = await _rpc('my_public_trip', {'p_journey_id': journeyId});
    return json == null ? null : PublicTripOwnerView.fromJson(json);
  }

  @override
  Future<PublicTripOwnerView> prepare({
    required String journeyId,
    required String requestId,
    required String title,
    required List<PublicTripMomentChoice> moments,
    required List<String> photoIds,
    required int startTrimMeters,
    required int endTrimMeters,
  }) async {
    final json = await _rpc('prepare_public_trip', {
      'p_journey_id': journeyId,
      'p_request_id': requestId,
      'p_title': title,
      'p_moments': [
        for (final moment in moments)
          {'kind': moment.kind, 'sequence_number': moment.sequenceNumber},
      ],
      'p_photo_ids': photoIds,
      'p_start_trim_m': startTrimMeters,
      'p_end_trim_m': endTrimMeters,
    });
    return PublicTripOwnerView.fromJson(_required(json));
  }

  @override
  Future<PublicTripOwnerView> submit({
    required String publicationId,
    required int revision,
    required String contentHash,
  }) async {
    final json = await _rpc('submit_public_trip', {
      'p_publication_id': publicationId,
      'p_revision': revision,
      'p_content_hash': contentHash,
      'p_terms_version': publicTripTermsVersion,
    });
    return PublicTripOwnerView.fromJson(_required(json));
  }

  @override
  Future<void> withdraw({
    required String publicationId,
    required String requestId,
  }) async {
    await _rpc('withdraw_public_trip', {
      'p_publication_id': publicationId,
      'p_request_id': requestId,
    });
  }

  @override
  Future<PublicTripSharePreferences> sharePreferences() async {
    final json = await _rpc('get_public_trip_share_preferences', const {});
    return PublicTripSharePreferences.fromJson(_required(json));
  }

  @override
  Future<PublicTripSharePreferences> saveSharePreferences(
    PublicTripSharePreferences preferences,
  ) async {
    final json = await _rpc('set_public_trip_share_preferences', {
      'p_county_crossing': preferences.countyCrossing,
      'p_elevation_peak': preferences.elevationPeak,
      'p_top_speed': preferences.topSpeed,
      'p_long_stop': preferences.longStop,
      'p_recording_break': preferences.recordingBreak,
      'p_photos': preferences.photos,
      'p_trim_m': preferences.trimMeters,
    });
    return PublicTripSharePreferences.fromJson(_required(json));
  }

  Map<String, dynamic> _required(Map<String, dynamic>? json) =>
      json ?? (throw const PublicTripFailure('The server sent no answer.'));

  Future<Map<String, dynamic>?> _rpc(
    String name,
    Map<String, dynamic> params,
  ) async {
    try {
      final result = await client
          .rpc<dynamic>(name, params: params)
          .timeout(_timeout);
      return result is Map<String, dynamic> ? result : null;
    } on PostgrestException catch (error) {
      throw PublicTripFailure(_friendly(error));
    } on Object {
      throw const PublicTripFailure(
        'Could not reach Kaunti47. Check your connection and try again.',
      );
    }
  }

  /// The server's refusals are written for people; only the generic
  /// permission error needs a friendlier line.
  static String _friendly(PostgrestException error) {
    final message = error.message;
    if (message == 'Public trips unavailable') {
      return 'Public trips are not available for your account right now.';
    }
    return message.isEmpty ? 'The request was refused.' : message;
  }
}
