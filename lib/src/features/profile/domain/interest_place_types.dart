import 'place_interest.dart';

/// Which `places.type` values count as a match for each interest. The
/// source of truth is the `interest_place_types` table; [fallback] mirrors
/// its seed so matching still works offline and before it has loaded.
class InterestPlaceTypes {
  const InterestPlaceTypes(this._byInterest);

  /// Builds from table rows: `{interest_key, place_type}`. Unknown keys and
  /// blank types are skipped.
  factory InterestPlaceTypes.fromRows(Iterable<Map<dynamic, dynamic>> rows) {
    final byInterest = <PlaceInterest, Set<String>>{};
    for (final row in rows) {
      final interest = PlaceInterest.fromKey('${row['interest_key']}');
      final type = '${row['place_type']}'.trim().toLowerCase();
      if (interest == null || type.isEmpty) continue;
      (byInterest[interest] ??= <String>{}).add(type);
    }
    return InterestPlaceTypes(byInterest);
  }

  final Map<PlaceInterest, Set<String>> _byInterest;

  bool get isEmpty => _byInterest.isEmpty;

  /// The first of [picks] (in the order picked) that [placeType] counts
  /// toward, or null when it matches none of them.
  PlaceInterest? matchFor(String placeType, Iterable<PlaceInterest> picks) {
    final type = placeType.trim().toLowerCase();
    for (final pick in picks) {
      if (_byInterest[pick]?.contains(type) ?? false) return pick;
    }
    return null;
  }

  static const fallback = InterestPlaceTypes({
    PlaceInterest.nature: {'park', 'forest', 'reserve', 'garden', 'conservancy'},
    PlaceInterest.water: {
      'waterfall',
      'hike',
      'hiking',
      'trail',
      'gorge',
      'river',
    },
    PlaceInterest.coast: {'shore', 'beach', 'coast', 'island'},
    PlaceInterest.culture: {
      'culture',
      'museum',
      'heritage',
      'historic',
      'monument',
    },
    PlaceInterest.wild: {
      'park',
      'wildlife',
      'reserve',
      'conservancy',
      'sanctuary',
    },
    PlaceInterest.food: {'market', 'restaurant', 'food'},
    PlaceInterest.views: {'viewpoint', 'view', 'escarpment', 'lookout'},
    PlaceInterest.relax: {'spring', 'hot_spring', 'lake', 'retreat', 'stay'},
  });
}
