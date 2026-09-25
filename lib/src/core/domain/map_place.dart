/// A place from the `places` table, as a pin on the real (Mapbox) map.
class MapPlace {
  const MapPlace({
    required this.id,
    required this.name,
    required this.type,
    required this.countyCode,
    required this.lat,
    required this.lng,
    this.summary,
    this.thumbnailUrl,
  });

  final String id;
  final String name;

  /// `park`, `museum`, `culture`, `heritage`, `shore`, ...
  final String type;
  final int countyCode;
  final double lat;
  final double lng;
  final String? summary;

  /// First `place_images` thumbnail by sort order, if the place has one.
  final String? thumbnailUrl;
}
