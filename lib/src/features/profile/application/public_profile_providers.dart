import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/services/supabase_client_provider.dart';
import '../../auth/application/auth_providers.dart';
import '../data/profile_snapshot_store.dart';
import '../data/public_profile_repository.dart';
import '../domain/public_profile.dart';
import 'trip_stats_providers.dart';

part 'public_profile_providers.g.dart';

/// The account's public identity in the cloud, or null when the build has
/// no Supabase.
@riverpod
PublicProfileRepository? publicProfileRepository(Ref ref) {
  final client = ref.watch(supabaseClientProvider);
  return client == null ? null : SupabasePublicProfileRepository(client);
}

/// The signed-in account's display name, handle and avatar. Reloads when
/// the account changes; Edit Profile invalidates this after a successful
/// save or avatar upload. Kept alive so Home's avatar and Profile read one
/// loaded copy instead of fetching again (and flashing the initial) each
/// time either screen appears.
@Riverpod(keepAlive: true)
Future<PublicProfile?> myPublicProfile(Ref ref) async {
  ref.watch(authUserIdProvider);
  final userId = ref.watch(currentUserIdProvider)();
  final repository = ref.watch(publicProfileRepositoryProvider);
  if (userId == null || repository == null) return null;
  const store = ProfileSnapshotStore();
  try {
    final profile = await repository.fetch();
    if (profile != null) {
      await store.writeProfile(userId, profile, DateTime.now());
    }
    return profile;
  } on Object {
    // No connection: the copy from the last good load, if there is one.
    final saved = await store.readProfile(userId);
    if (saved == null) rethrow;
    return saved;
  }
}

/// When the Profile values on screen were last saved, for the "Saved"
/// chip while offline. Re-reads whenever either value reloads.
@riverpod
Future<DateTime?> profileSavedAt(Ref ref) async {
  ref.watch(myPublicProfileProvider);
  ref.watch(tripStatsProvider);
  final userId = ref.watch(currentUserIdProvider)();
  if (userId == null) return null;
  return const ProfileSnapshotStore().savedAt(userId);
}
