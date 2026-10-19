import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/services/app_current_location.dart';
import '../../../core/services/connectivity_provider.dart';
import '../../../core/services/fail_fast.dart';
import '../../../core/services/supabase_client_provider.dart';
import '../../auth/application/auth_providers.dart';
import '../../detection/application/visit_sync.dart';
import '../data/badge_spin_history.dart';
import '../data/badges_snapshot_store.dart';
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

/// The signed-in user's badge collection. The copy from the last good load
/// shows at once ([BadgeCollection.savedAt] set), then the live one replaces
/// it when it arrives; offline, the saved copy simply stays. Reloads when
/// the account changes, when a visit syncs (a new badge or depth) and when
/// the connection drops or returns.
@riverpod
Stream<BadgeCollection> badgeCollection(Ref ref) async* {
  ref.watch(authUserIdProvider);
  ref.watch(visitSyncProvider);
  ref.watch(connectivityProvider.select((s) => s.isOffline));
  final userId = ref.watch(currentUserIdProvider)();
  final repository = ref.watch(badgesRepositoryProvider);
  if (userId == null || repository == null) {
    yield BadgeCollection.from(visitStates: const {}, ranks: const {});
    return;
  }
  const store = BadgesSnapshotStore();
  final saved = await store.read(userId);
  if (saved != null) {
    yield BadgeCollection.from(
      visitStates: saved.visitStates,
      ranks: saved.ranks,
      savedAt: saved.savedAt,
      firstStampAt: saved.firstStampAt,
      checkIns: saved.checkIns,
    );
  }
  try {
    final data = await failFast(ref, () => repository.raw(userId));
    await store.write(
      userId,
      visitStates: data.visitStates,
      ranks: data.ranks,
      now: DateTime.now(),
      firstStampAt: data.firstStampAt,
      checkIns: data.checkIns,
    );
    yield BadgeCollection.from(
      visitStates: data.visitStates,
      ranks: data.ranks,
      firstStampAt: data.firstStampAt,
      checkIns: data.checkIns,
    );
  } on Object {
    // No connection: the saved copy already on screen stays. With none
    // saved the error stands and the screen says it needs a connection.
    if (saved == null) rethrow;
  }
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
Future<AppLocationFix?> badgeUserLocation(Ref ref) => AppCurrentLocation.read();

/// Spin the coin on every open (testing); false = first open only.
const spinEveryOpen = true;

@riverpod
BadgeSpinHistory badgeSpinHistory(Ref ref) => const BadgeSpinHistory();

/// Whether this earned badge's coin should spin as its sheet opens: only
/// the first time the account opens it on this phone. Asking records it.
///
/// TEMPORARY while the spin is being tuned: [spinEveryOpen] makes every
/// open spin. Set it back to false before release.
@riverpod
Future<bool> badgeFirstSpin(Ref ref, int countyCode) async {
  if (spinEveryOpen) return true;
  final userId = ref.watch(currentUserIdProvider)();
  if (userId == null) return false;
  return ref.read(badgeSpinHistoryProvider).claimFirstSpin(userId, countyCode);
}
