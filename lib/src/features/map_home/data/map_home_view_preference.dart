import 'package:shared_preferences/shared_preferences.dart';

/// Remembers whether the user has manually chosen the drawn (offline-style)
/// county map over the real Mapbox map, so Home reopens on whichever one
/// they last picked. Independent of the automatic real-map-failed fallback:
/// that always shows the drawn map regardless of this preference, and never
/// writes to it.
class MapHomeViewPreference {
  const MapHomeViewPreference();

  static const _preferDrawnKey = 'map_home.prefer_drawn_map';

  static const _celebratedClaimKey = 'map_home.celebrated_claim_at';

  /// The claim whose celebration Home has already shown, so a claim is
  /// celebrated on one open only.
  Future<DateTime?> celebratedClaimAt() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_celebratedClaimKey);
    return raw == null ? null : DateTime.tryParse(raw);
  }

  Future<void> setCelebratedClaimAt(DateTime claimedAt) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _celebratedClaimKey,
      claimedAt.toUtc().toIso8601String(),
    );
  }

  Future<bool> preferDrawnMap() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_preferDrawnKey) ?? false;
  }

  Future<void> setPreferDrawnMap(bool preferDrawn) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_preferDrawnKey, preferDrawn);
  }
}
