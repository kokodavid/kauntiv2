import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/services/supabase_client_provider.dart';
import '../../auth/application/auth_providers.dart';
import '../data/profile_settings_repository.dart';
import '../domain/profile_settings.dart';

part 'profile_settings_providers.g.dart';

@riverpod
ProfileSettingsRepository? profileSettingsRepository(Ref ref) {
  final client = ref.watch(supabaseClientProvider);
  return client == null ? null : SupabaseProfileSettingsRepository(client);
}

/// Settings screen state: the six preference columns on `profiles`,
/// updated optimistically (each setter flips the toggle immediately, then
/// persists, reverting on failure) so switches feel instant.
@riverpod
class ProfileSettingsController extends _$ProfileSettingsController {
  @override
  Future<ProfileSettings> build() async {
    ref.watch(authUserIdProvider);
    final repository = ref.watch(profileSettingsRepositoryProvider);
    if (repository == null) {
      return const ProfileSettings(
        mapVisibility: MapVisibility.friends,
        showOnLeaderboards: true,
        notifyBadgeUnlocks: true,
        notifyCountyNudges: true,
        sideQuestRadiusKm: 100,
        locationMode: LocationMode.automatic,
      );
    }
    return repository.fetch();
  }

  Future<void> _apply(
    ProfileSettings Function(ProfileSettings) optimistic,
    Map<String, Object?> columns,
  ) async {
    final current = state.value;
    if (current == null) return;
    state = AsyncValue.data(optimistic(current));
    final repository = ref.read(profileSettingsRepositoryProvider);
    if (repository == null) return;
    try {
      await repository.update(columns);
    } on Object {
      if (ref.mounted) state = AsyncValue.data(current);
      rethrow;
    }
  }

  Future<void> setMapVisibility(MapVisibility value) => _apply(
    (s) => s.copyWith(mapVisibility: value),
    {'map_visibility': value.column},
  );

  Future<void> setShowOnLeaderboards(bool value) => _apply(
    (s) => s.copyWith(showOnLeaderboards: value),
    {'show_on_leaderboards': value},
  );

  Future<void> setNotifyBadgeUnlocks(bool value) => _apply(
    (s) => s.copyWith(notifyBadgeUnlocks: value),
    {'notify_badge_unlocks': value},
  );

  Future<void> setNotifyCountyNudges(bool value) => _apply(
    (s) => s.copyWith(notifyCountyNudges: value),
    {'notify_county_nudges': value},
  );

  Future<void> setSideQuestRadiusKm(int value) => _apply(
    (s) => s.copyWith(sideQuestRadiusKm: value),
    {'side_quest_radius_km': value},
  );

  /// Saved as a preference only -- see [LocationMode]'s doc comment: this
  /// does not yet change what [DetectionController] actually does.
  Future<void> setLocationMode(LocationMode value) => _apply(
    (s) => s.copyWith(locationMode: value),
    {'location_mode': value.column},
  );
}
