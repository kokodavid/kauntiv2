import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/auth_providers.dart';
import '../domain/journey_media_quota.dart';
import 'journey_cloud_providers.dart';

/// The signed-in account's per-Trip photo limit, read live from the server.
/// Null when it can't be read (offline): the app then doesn't pre-trim, and
/// the server's own check still applies when photos upload.
final journeyMediaLimitProvider = FutureProvider.autoDispose<JourneyMediaLimit?>((
  ref,
) async {
  ref.watch(authUserIdProvider);
  final cloud = ref.watch(supabaseJourneyRepositoryProvider);
  if (cloud == null) return null;
  try {
    return await cloud.mediaLimit();
  } on Object {
    return null;
  }
});
