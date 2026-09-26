import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/services/supabase_client_provider.dart';
import '../../auth/application/auth_providers.dart';
import '../../detection/application/visit_sync.dart';
import '../data/supabase_badges_repository.dart';
import '../domain/badge_collection.dart';

part 'badges_providers.g.dart';

/// Badges in the cloud, or null when the build has no Supabase.
@riverpod
SupabaseBadgesRepository? badgesRepository(Ref ref) {
  final client = ref.watch(supabaseClientProvider);
  return client == null ? null : SupabaseBadgesRepository(client);
}

/// The signed-in user's badge collection. Reloads when the account
/// changes and when a visit syncs (a new badge or depth).
@riverpod
Future<BadgeCollection> badgeCollection(Ref ref) async {
  ref.watch(authUserIdProvider);
  ref.watch(visitSyncProvider);
  final userId = ref.watch(currentUserIdProvider)();
  final repository = ref.watch(badgesRepositoryProvider);
  if (userId == null || repository == null) {
    return BadgeCollection.from(visitStates: const {}, ranks: const {});
  }
  return repository.collection(userId);
}
