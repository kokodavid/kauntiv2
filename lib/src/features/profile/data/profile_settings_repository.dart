import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/profile_settings.dart';

abstract interface class ProfileSettingsRepository {
  Future<ProfileSettings> fetch();
  Future<void> update(Map<String, Object?> columns);
}

/// The six settings columns on `profiles` (`map_visibility`,
/// `show_on_leaderboards`, `notify_badge_unlocks`, `notify_county_nudges`,
/// `side_quest_radius_km`, `location_mode`) are plain user-owned
/// preference rows -- `profiles` already has owner `select`/`update` RLS
/// (`create_profiles.sql`), so a bare client update is the right pattern
/// here (security plan §3: RPCs are for anything beyond simple
/// user-owned preference rows, which this is).
class SupabaseProfileSettingsRepository implements ProfileSettingsRepository {
  const SupabaseProfileSettingsRepository(this.client);

  final SupabaseClient client;

  static const _timeout = Duration(seconds: 8);
  static const _columns =
      'map_visibility, show_on_leaderboards, notify_badge_unlocks, '
      'notify_county_nudges, side_quest_radius_km, location_mode';

  String _owner() {
    final owner = client.auth.currentUser?.id;
    if (owner == null) {
      throw StateError('Profile settings require a session');
    }
    return owner;
  }

  @override
  Future<ProfileSettings> fetch() async {
    final owner = _owner();
    final row = await client
        .from('profiles')
        .select(_columns)
        .eq('id', owner)
        .maybeSingle()
        .timeout(_timeout);
    return ProfileSettings(
      mapVisibility: MapVisibility.fromColumn(
        row?['map_visibility'] as String? ?? 'friends',
      ),
      showOnLeaderboards: row?['show_on_leaderboards'] as bool? ?? true,
      notifyBadgeUnlocks: row?['notify_badge_unlocks'] as bool? ?? true,
      notifyCountyNudges: row?['notify_county_nudges'] as bool? ?? true,
      sideQuestRadiusKm: row?['side_quest_radius_km'] as int? ?? 100,
      locationMode: LocationMode.fromColumn(
        row?['location_mode'] as String? ?? 'automatic',
      ),
    );
  }

  @override
  Future<void> update(Map<String, Object?> columns) async {
    final owner = _owner();
    await client
        .from('profiles')
        .upsert({
          'id': owner,
          ...columns,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .timeout(_timeout);
  }
}
