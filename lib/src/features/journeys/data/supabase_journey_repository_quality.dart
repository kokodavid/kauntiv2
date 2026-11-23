part of 'supabase_journey_repository.dart';

extension SupabaseJourneyQuality on SupabaseJourneyRepository {
  /// Sends how well a Trip recorded (counts only) with the phone and app
  /// version, for the team's quality view. Call after upload succeeds.
  Future<void> saveQuality({
    required String id,
    required JourneyQuality quality,
  }) async {
    final context = await const JourneyDeviceContextSource().capture();
    await _client
        .rpc<dynamic>(
          'save_journey_quality',
          params: {
            'p_journey_id': id,
            'p_summary': quality.toJson(),
            'p_app_version': context.appVersion,
            'p_platform': context.platform,
            'p_os_version': context.osVersion,
            'p_device_model': context.deviceModel,
          },
        )
        .timeout(SupabaseJourneyRepository._timeout);
  }
}
