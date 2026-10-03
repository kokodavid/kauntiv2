part of 'supabase_journey_repository.dart';

const _mediaBucket = 'journey-media';

extension SupabaseJourneyRepositoryMedia on SupabaseJourneyRepository {
  /// Sets or clears the cover photo through the owner-checked RPC.
  Future<void> setCoverPhoto({
    required String userId,
    required String id,
    required String? mediaId,
  }) => _client
      .rpc<Object?>(
        'set_trip_cover_photo',
        params: {
          'p_user_id': userId,
          'p_journey_id': id,
          'p_media_id': mediaId,
        },
      )
      .timeout(SupabaseJourneyRepository._timeout);

  /// Uploads a private photo and records its account-scoped metadata.
  Future<void> uploadMedia({
    required String userId,
    required String journeyId,
    required String id,
    required String localPath,
    required DateTime capturedAt,
    double? latitude,
    double? longitude,
  }) async {
    final extension = localPath.contains('.')
        ? localPath.substring(localPath.lastIndexOf('.'))
        : '.jpg';
    final storagePath = '$userId/$journeyId/$id$extension';
    await _client.storage
        .from(_mediaBucket)
        .upload(
          storagePath,
          File(localPath),
          fileOptions: const FileOptions(upsert: true),
        )
        .timeout(SupabaseJourneyRepository._uploadTimeout);
    await _client
        .from('journey_media')
        .upsert({
          'journey_id': journeyId,
          'user_id': userId,
          'storage_path': storagePath,
          'captured_at': capturedAt.toUtc().toIso8601String(),
          'latitude': latitude,
          'longitude': longitude,
        }, onConflict: 'storage_path')
        .timeout(SupabaseJourneyRepository._timeout);
  }

  /// Reads this Trip's uploaded photos with short-lived signed URLs.
  Future<List<JourneyMediaItem>> media(String journeyId) async {
    final rows = await _client
        .from('journey_media')
        .select('id, storage_path, captured_at, latitude, longitude')
        .eq('journey_id', journeyId)
        .order('captured_at', ascending: true)
        .timeout(SupabaseJourneyRepository._timeout);
    final urls = await Future.wait([
      for (final row in rows)
        _client.storage
            .from(_mediaBucket)
            .createSignedUrl(row['storage_path'] as String, 3600)
            .timeout(SupabaseJourneyRepository._timeout),
    ]);
    return [
      for (var i = 0; i < rows.length; i++)
        JourneyMediaItem(
          id: rows[i]['id'] as String,
          url: urls[i],
          capturedAt: DateTime.parse(rows[i]['captured_at'] as String),
          latitude: (rows[i]['latitude'] as num?)?.toDouble(),
          longitude: (rows[i]['longitude'] as num?)?.toDouble(),
        ),
    ];
  }
}
