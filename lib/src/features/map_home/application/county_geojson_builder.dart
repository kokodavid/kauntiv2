import 'dart:convert';

import '../domain/map_home_models.dart';

/// Builds the GeoJSON the Pro (Mapbox) map renders: the bundled county
/// boundaries (`assets/geo/kenya_counties.geojson`) with each feature's
/// `state` property set from the user's badges, so the map can colour
/// counties with a data-driven style expression.
///
/// `state` is the [MapHomeCountyBadgeState] name, or `home` for the user's
/// home county (unless it is still locked), mirroring the drawn map.
abstract final class CountyGeoJsonBuilder {
  static String withBadgeStates({
    required String boundariesGeoJson,
    required List<MapHomeCountyBadge> badges,
    String? homeCountySlug,
  }) {
    final stateByCode = {
      for (final badge in badges)
        badge.county.code: _stateFor(badge, homeCountySlug),
    };

    final collection = jsonDecode(boundariesGeoJson) as Map<String, Object?>;
    final features = (collection['features'] as List<Object?>)
        .cast<Map<String, Object?>>();
    for (final feature in features) {
      final properties = feature['properties'] as Map<String, Object?>;
      final code = properties['code'] as int;
      properties['state'] =
          stateByCode[code] ?? MapHomeCountyBadgeState.locked.name;
    }
    return jsonEncode(collection);
  }

  static String _stateFor(MapHomeCountyBadge badge, String? homeCountySlug) {
    final isHome = badge.county.slug == homeCountySlug;
    if (isHome && badge.state != MapHomeCountyBadgeState.locked) return 'home';
    return badge.state.name;
  }
}
