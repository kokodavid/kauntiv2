/// A place as a trip plan shows it: on a day, on Places to visit, or as a
/// start or overnight point. The server only returns places app users can
/// see, so a removed place simply drops out of the plan.
class PlanPlace {
  const PlanPlace({
    required this.id,
    required this.name,
    required this.type,
    required this.countyCode,
    this.lat,
    this.lng,
    this.thumbnailUrl,
    this.isCustom = false,
    this.address,
  });

  final String id;
  final String name;

  /// The place type key (`waterfall`, `park`...), as in `core/domain`.
  final String type;
  final int countyCode;
  final double? lat;
  final double? lng;
  final String? thumbnailUrl;

  /// A place from outside the Kaunti47 list (searched for or a dropped pin).
  /// Its [id] is the custom place's id, not a `places` row.
  final bool isCustom;
  final String? address;

  bool get hasPosition => lat != null && lng != null;

  /// Null when [json] isn't a usable place (missing id, name or county).
  static PlanPlace? fromJson(Object? json) {
    if (json is! Map) return null;
    final id = json['id'];
    final name = json['name'];
    final county = json['county_code'];
    if (id is! String || name is! String || county is! num) return null;
    final lat = json['lat'];
    final lng = json['lng'];
    final thumbnail = json['thumbnail_url'];
    return PlanPlace(
      id: id,
      name: name,
      type: json['custom'] == true || json['type'] is! String
          ? ''
          : json['type'] as String,
      countyCode: county.toInt(),
      lat: lat is num ? lat.toDouble() : null,
      lng: lng is num ? lng.toDouble() : null,
      thumbnailUrl: thumbnail is String && thumbnail.isNotEmpty
          ? thumbnail
          : null,
      isCustom: json['custom'] == true,
      address: json['address'] is String && (json['address'] as String).isNotEmpty
          ? json['address'] as String
          : null,
    );
  }

  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'type': type,
    'county_code': countyCode,
    'lat': lat,
    'lng': lng,
    'thumbnail_url': thumbnailUrl,
    if (isCustom) 'custom': true,
    if (address != null) 'address': address,
  };
}
