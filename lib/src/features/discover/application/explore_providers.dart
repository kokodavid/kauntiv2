import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/services/supabase_client_provider.dart';
import '../data/discover_detail_repository.dart';
import '../data/explore_repository.dart';
import '../data/supabase_discover_detail_repository.dart';
import '../data/supabase_explore_repository.dart';
import '../domain/explore_board.dart';

part 'explore_providers.g.dart';

@riverpod
ExploreRepository exploreRepository(Ref ref) {
  final client = ref.watch(supabaseClientProvider);
  if (client == null) throw StateError(_notConfigured);
  return SupabaseExploreRepository(client);
}

@riverpod
DiscoverDetailRepository discoverDetailRepository(Ref ref) {
  final client = ref.watch(supabaseClientProvider);
  if (client == null) throw StateError(_notConfigured);
  return SupabaseDiscoverDetailRepository(client);
}

const _notConfigured = 'Supabase is not configured for this build.';

/// Explore's board. Kept alive by the tab shell, which keeps Explore
/// mounted once visited; invalidate it to reload.
@riverpod
Future<ExploreBoard> exploreBoard(Ref ref) =>
    ref.watch(exploreRepositoryProvider).loadBoard();

/// Which Explore tab is showing.
@riverpod
class ExploreTabSelection extends _$ExploreTabSelection {
  @override
  ExploreTab build() => ExploreTab.mine;

  void select(ExploreTab tab) => state = tab;
}

/// The Explore search text, applied across tabs.
@riverpod
class ExploreSearchQuery extends _$ExploreSearchQuery {
  @override
  String build() => '';

  void update(String query) => state = query;
}

/// Place save changes made from Explore since the board loaded, by place
/// id, so rows rebuilt after scrolling show the latest state.
@riverpod
class ExploreSavedPlaces extends _$ExploreSavedPlaces {
  @override
  Map<String, bool> build() => const {};

  /// Applies [saved] optimistically, then writes it. On failure the
  /// previous value is restored and the error rethrown for the UI. On
  /// success the board refreshes in place so SAVED picks the change up.
  Future<void> setSaved({
    required int countyCode,
    required String placeId,
    required bool saved,
  }) async {
    final before = state;
    state = {...state, placeId: saved};
    try {
      await ref
          .read(discoverDetailRepositoryProvider)
          .setPlaceSaved(
            countyCode: countyCode,
            placeId: placeId,
            saved: saved,
          );
    } on Object {
      if (ref.mounted) state = before;
      rethrow;
    }
    if (ref.mounted) ref.invalidate(exploreBoardProvider);
  }
}

/// County-only saves from UNCLAIMED's Save button, by county code.
@riverpod
class ExploreSavedCounties extends _$ExploreSavedCounties {
  @override
  Map<int, bool> build() => const {};

  /// Same contract as [ExploreSavedPlaces.setSaved].
  Future<void> setSaved({required int countyCode, required bool saved}) async {
    final before = state;
    state = {...state, countyCode: saved};
    try {
      await ref
          .read(exploreRepositoryProvider)
          .setCountySaved(countyCode: countyCode, saved: saved);
    } on Object {
      if (ref.mounted) state = before;
      rethrow;
    }
    if (ref.mounted) ref.invalidate(exploreBoardProvider);
  }
}

/// Hand-ticked SAVED places since the board loaded, by place id.
@riverpod
class ExploreTickedPlaces extends _$ExploreTickedPlaces {
  @override
  Map<String, bool> build() => const {};

  /// Applies [ticked] optimistically, then writes it; restores and
  /// rethrows on failure. No board refresh: only the checkbox changes.
  Future<void> setTicked({
    required String placeId,
    required bool ticked,
  }) async {
    final before = state;
    state = {...state, placeId: ticked};
    try {
      await ref
          .read(exploreRepositoryProvider)
          .setPlaceTicked(placeId: placeId, ticked: ticked);
    } on Object {
      if (ref.mounted) state = before;
      rethrow;
    }
  }
}
