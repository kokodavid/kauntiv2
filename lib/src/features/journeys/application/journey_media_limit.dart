import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../auth/application/auth_providers.dart';
import '../domain/journey_media_quota.dart';
import 'journey_cloud_providers.dart';

part 'journey_media_limit.g.dart';

/// The signed-in account's per-Trip photo limit, read live from the server.
/// Null when it can't be read (offline): the app then doesn't pre-trim, and
/// the server's own check still applies when photos upload.
@riverpod
Future<JourneyMediaLimit?> journeyMediaLimit(Ref ref) async {
  ref.watch(authUserIdProvider);
  final cloud = ref.watch(supabaseJourneyRepositoryProvider);
  if (cloud == null) return null;
  try {
    return await cloud.mediaLimit();
  } on Object {
    return null;
  }
}
