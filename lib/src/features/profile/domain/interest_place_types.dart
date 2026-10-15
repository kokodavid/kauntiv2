import '../../../core/domain/place_type.dart';
import 'place_interest.dart';

/// Which place types count as a match for each interest. The source of
/// truth is the `interest_place_types` table; [fallback] mirrors it so
/// matching still works offline and before it has loaded. Types are
/// compared by [PlaceType] key, so old spellings ("shore") still match.
class InterestPlaceTypes {
  const InterestPlaceTypes(this._byInterest);

  /// Builds from table rows: `{interest_key, place_type}`. Unknown keys and
  /// blank types are skipped.
  factory InterestPlaceTypes.fromRows(Iterable<Map<dynamic, dynamic>> rows) {
    final byInterest = <PlaceInterest, Set<String>>{};
    for (final row in rows) {
      final interest = PlaceInterest.fromKey('${row['interest_key']}');
      final raw = '${row['place_type']}';
      if (interest == null || raw.trim().isEmpty) continue;
      final type = PlaceType.of(raw).key;
      (byInterest[interest] ??= <String>{}).add(type);
    }
    return InterestPlaceTypes(byInterest);
  }

  final Map<PlaceInterest, Set<String>> _byInterest;

  bool get isEmpty => _byInterest.isEmpty;

  /// The first of [picks] (in the order picked) that [placeType] counts
  /// toward, or null when it matches none of them.
  PlaceInterest? matchFor(String placeType, Iterable<PlaceInterest> picks) {
    final type = PlaceType.of(placeType).key;
    for (final pick in picks) {
      if (_byInterest[pick]?.contains(type) ?? false) return pick;
    }
    return null;
  }

  static const fallback = InterestPlaceTypes({
    PlaceInterest.nature: {
      'park',
      'forest',
      'garden',
      'conservancy',
      'mountain',
      'cave',
    },
    PlaceInterest.water: {'waterfall', 'hike', 'river'},
    PlaceInterest.coast: {'beach', 'island'},
    PlaceInterest.culture: {
      'museum',
      'historic_site',
      'monument',
      'cultural_site',
    },
    PlaceInterest.wild: {'park', 'conservancy'},
    PlaceInterest.food: {'market', 'food'},
    PlaceInterest.views: {'viewpoint', 'mountain'},
    PlaceInterest.relax: {'hot_spring', 'lake', 'stay'},
  });
}
