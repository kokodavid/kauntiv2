import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/services/supabase_client_provider.dart';
import '../data/journey_media_upload_queue.dart';
import '../data/journey_upload_queue.dart';
import '../data/supabase_journey_repository.dart';
import 'journey_providers.dart';

part 'journey_cloud_providers.g.dart';

/// Cloud Journeys, or null when the build has no Supabase.
@Riverpod(keepAlive: true)
SupabaseJourneyRepository? supabaseJourneyRepository(Ref ref) {
  final client = ref.watch(supabaseClientProvider);
  return client == null ? null : SupabaseJourneyRepository(client);
}

/// Uploads completed Journeys, or null without Supabase.
@Riverpod(keepAlive: true)
JourneyUploadQueue? journeyUploadQueue(Ref ref) {
  final cloud = ref.watch(supabaseJourneyRepositoryProvider);
  if (cloud == null) return null;
  return JourneyUploadQueue.supabase(ref.watch(journeyDatabaseProvider), cloud);
}

/// Uploads captured Trip photos, or null without Supabase.
@Riverpod(keepAlive: true)
JourneyMediaUploadQueue? journeyMediaUploadQueue(Ref ref) {
  final cloud = ref.watch(supabaseJourneyRepositoryProvider);
  if (cloud == null) return null;
  return JourneyMediaUploadQueue.supabase(
    ref.watch(journeyDatabaseProvider),
    cloud,
  );
}

Future<void> updateJourneyCoverPhoto(
  SupabaseJourneyRepository repository, {
  required String userId,
  required String id,
  required String? mediaId,
}) => repository.setCoverPhoto(userId: userId, id: id, mediaId: mediaId);

Future<void> deleteJourneyMediaPhoto(
  SupabaseJourneyRepository repository, {
  required String userId,
  required String journeyId,
  required String mediaId,
}) => repository.deleteMedia(
  userId: userId,
  journeyId: journeyId,
  mediaId: mediaId,
);
