import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/services/app_current_location.dart';
import '../../../core/services/supabase_client_provider.dart';
import '../../auth/application/auth_providers.dart';
import '../../detection/application/visit_sync.dart';
import '../data/badge_spin_history.dart';
import '../data/supabase_badges_repository.dart';
import '../domain/badge_collection.dart';
import '../domain/county_badge_detail.dart';

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

/// One county's badge in detail, for the badge sheet. Reloads with the
/// collection (account change, visit sync).
@riverpod
Future<CountyBadgeDetail> countyBadgeDetail(Ref ref, int countyCode) async {
  ref.watch(authUserIdProvider);
  ref.watch(visitSyncProvider);
  final repository = ref.watch(badgesRepositoryProvider);
  if (repository == null) return const CountyBadgeDetail();
  return repository.detail(countyCode);
}

/// Where the user is now, for "Places to start with" distances; null
/// without permission or a fix. A one-shot foreground read, never stored.
@riverpod
Future<AppLocationFix?> badgeUserLocation(Ref ref) =>
    AppCurrentLocation.read();

@riverpod
BadgeSpinHistory badgeSpinHistory(Ref ref) => const BadgeSpinHistory();

/// Whether this earned badge's coin should spin as its sheet opens: only
/// the first time the account opens it on this phone. Asking records it.
@riverpod
Future<bool> badgeFirstSpin(Ref ref, int countyCode) async {
  final userId = ref.watch(currentUserIdProvider)();
  if (userId == null) return false;
  return ref.read(badgeSpinHistoryProvider).claimFirstSpin(userId, countyCode);
}
