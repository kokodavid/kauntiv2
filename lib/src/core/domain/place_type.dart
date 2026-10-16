import 'place_type_aliases.dart';

/// Broad families of place types. The map colours pins by family, and the
/// place detail pill picks its dot colour from it.
enum PlaceTypeFamily {
  nature,
  water,
  coast,
  wildlife,
  heritage,
  museum,
  culture,
  food,
  stay,
  other,
}

/// A kind of place (waterfall, beach, museum...).
///
/// Mirrors `public.place_types` and `public.place_type_aliases`
/// (`supabase/migrations/20261018100000_place_types.sql`); keep the two in
/// step. [of] also understands the old free-text spellings ("shore",
/// "heritage", "hiking"), so the app reads correctly against a database
/// that has not run that migration yet.
final class PlaceType {
  const PlaceType._(this.key, this.label, this.pluralLabel, this.family);

  /// The `places.type` value, e.g. `hot_spring`.
  final String key;

  /// Singular, for a pill on one place: "Hot spring".
  final String label;

  /// Plural, for a category filter: "Hot springs".
  final String pluralLabel;
  final PlaceTypeFamily family;

  static const waterfall = PlaceType._(
    'waterfall',
    'Waterfall',
    'Waterfalls',
    PlaceTypeFamily.water,
  );
  static const hike = PlaceType._(
    'hike',
    'Hike',
    'Hikes',
    PlaceTypeFamily.nature,
  );
  static const mountain = PlaceType._(
    'mountain',
    'Mountain',
    'Mountains',
    PlaceTypeFamily.nature,
  );
  static const viewpoint = PlaceType._(
    'viewpoint',
    'Viewpoint',
    'Views',
    PlaceTypeFamily.nature,
  );
  static const beach = PlaceType._(
    'beach',
    'Beach',
    'Beaches',
    PlaceTypeFamily.coast,
  );
  static const island = PlaceType._(
    'island',
    'Island',
    'Islands',
    PlaceTypeFamily.coast,
  );
  static const marinePark = PlaceType._(
    'marine_park',
    'Marine park',
    'Marine parks',
    PlaceTypeFamily.coast,
  );
  static const lake = PlaceType._(
    'lake',
    'Lake',
    'Lakes',
    PlaceTypeFamily.water,
  );
  static const river = PlaceType._(
    'river',
    'River',
    'Rivers',
    PlaceTypeFamily.water,
  );
  static const hotSpring = PlaceType._(
    'hot_spring',
    'Hot spring',
    'Hot springs',
    PlaceTypeFamily.water,
  );
  static const park = PlaceType._(
    'park',
    'Park',
    'Parks',
    PlaceTypeFamily.nature,
  );
  static const conservancy = PlaceType._(
    'conservancy',
    'Conservancy',
    'Conservancies',
    PlaceTypeFamily.wildlife,
  );
  static const forest = PlaceType._(
    'forest',
    'Forest',
    'Forests',
    PlaceTypeFamily.nature,
  );
  static const cave = PlaceType._(
    'cave',
    'Cave',
    'Caves',
    PlaceTypeFamily.nature,
  );
  static const desert = PlaceType._(
    'desert',
    'Desert',
    'Deserts',
    PlaceTypeFamily.nature,
  );
  static const garden = PlaceType._(
    'garden',
    'Garden',
    'Gardens',
    PlaceTypeFamily.nature,
  );
  static const museum = PlaceType._(
    'museum',
    'Museum',
    'Museums',
    PlaceTypeFamily.museum,
  );
  static const historicSite = PlaceType._(
    'historic_site',
    'Historic site',
    'Historic sites',
    PlaceTypeFamily.heritage,
  );
  static const monument = PlaceType._(
    'monument',
    'Monument',
    'Monuments',
    PlaceTypeFamily.heritage,
  );
  static const landmark = PlaceType._(
    'landmark',
    'Landmark',
    'Landmarks',
    PlaceTypeFamily.culture,
  );
  static const culturalSite = PlaceType._(
    'cultural_site',
    'Cultural site',
    'Culture',
    PlaceTypeFamily.culture,
  );
  static const market = PlaceType._(
    'market',
    'Market',
    'Markets',
    PlaceTypeFamily.food,
  );
  static const food = PlaceType._(
    'food',
    'Food spot',
    'Food',
    PlaceTypeFamily.food,
  );
  static const stay = PlaceType._(
    'stay',
    'Stay',
    'Stays',
    PlaceTypeFamily.stay,
  );

  /// Used when a place has no type at all.
  static const unknown = PlaceType._(
    '',
    'Place',
    'Places',
    PlaceTypeFamily.other,
  );

  /// Every type on the list, in display order (`place_types.sort_order`).
  static const all = [
    waterfall,
    hike,
    mountain,
    viewpoint,
    beach,
    island,
    marinePark,
    lake,
    river,
    hotSpring,
    park,
    conservancy,
    forest,
    cave,
    desert,
    garden,
    museum,
    historicSite,
    monument,
    landmark,
    culturalSite,
    market,
    food,
    stay,
  ];

  static final Map<String, PlaceType> _byKey = {
    for (final type in all) type.key: type,
  };

  static final Map<String, String> _aliases = {
    for (final MapEntry(:key, :value) in placeTypeAliases.entries)
      for (final alias in value) alias: key,
  };

  /// Lower case, trimmed, with `_`, `-` and repeated spaces turned into one
  /// space (the same rule as `resolve_place_type`).
  static String normalise(String raw) =>
      raw.trim().toLowerCase().replaceAll(RegExp(r'[\s_-]+'), ' ');

  /// The type for a `places.type` value. Known keys and old spellings map
  /// to the list; anything else becomes an unlisted type that keeps its own
  /// key and a capitalised label, so nothing is shown as the wrong kind.
  static PlaceType of(String raw) {
    final normal = normalise(raw);
    if (normal.isEmpty) return unknown;
    final key = normal.replaceAll(' ', '_');
    final listed = _byKey[key] ?? _byKey[_aliases[normal]];
    if (listed != null) return listed;
    final label = '${normal[0].toUpperCase()}${normal.substring(1)}';
    return PlaceType._(key, label, label, PlaceTypeFamily.other);
  }

  /// Whether this type is on the list (not an unlisted spelling).
  bool get isListed => _byKey.containsKey(key);

  @override
  bool operator ==(Object other) => other is PlaceType && other.key == key;

  @override
  int get hashCode => key.hashCode;

  @override
  String toString() => 'PlaceType($key)';
}
