import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/services/supabase_client_provider.dart';
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
