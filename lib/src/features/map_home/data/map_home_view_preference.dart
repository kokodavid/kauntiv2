import 'package:shared_preferences/shared_preferences.dart';

/// Remembers whether the user has manually chosen the drawn (offline-style)
/// county map over the real Mapbox map, so Home reopens on whichever one
/// they last picked. Independent of the automatic real-map-failed fallback:
/// that always shows the drawn map regardless of this preference, and never
/// writes to it.
class MapHomeViewPreference {
  const MapHomeViewPreference();

  static const _preferDrawnKey = 'map_home.prefer_drawn_map';

  Future<bool> preferDrawnMap() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_preferDrawnKey) ?? false;
  }

  Future<void> setPreferDrawnMap(bool preferDrawn) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_preferDrawnKey, preferDrawn);
  }
}
