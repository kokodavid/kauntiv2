import '../../../core/domain/place_type.dart';
import 'place_interest.dart';

/// Which counties a type's link to an interest counts in.
enum InterestCountyScope {
  any,
  coastal,
  inland;

  static InterestCountyScope parse(Object? raw) => switch (raw) {
    'coastal' => coastal,
    'inland' => inland,
    _ => any,
  };

  /// Whether a county with [coastal] status is covered. An unknown status
  /// (the counties have not loaded) covers every scope.
  bool covers({bool? coastal}) => switch (this) {
    any => true,
    InterestCountyScope.coastal => coastal ?? true,
    inland => !(coastal ?? false),
  };
}

/// One place type's link to an interest.
class InterestLink {
  const InterestLink(
    this.type, {
    this.isPrimary = false,
    this.scope = InterestCountyScope.any,
  });

  /// A [PlaceType] key.
  final String type;

  /// Whether this is the type's home interest.
  final bool isPrimary;
  final InterestCountyScope scope;
}

/// Which place types count as a match for each interest. The source of
/// truth is the `interest_place_types` table; [fallback] mirrors it so
/// matching still works offline and before it has loaded. Types are
/// compared by [PlaceType] key, so old spellings ("shore") still match.
class InterestPlaceTypes {
  const InterestPlaceTypes(this._byInterest);

  /// Builds from table rows: `{interest_key, place_type}` plus, once the
  /// database has them, `is_primary` and `county_scope`. Blank types are
  /// skipped. Interests are matched by key, so one added in the backend
  /// works without an app update.
  factory InterestPlaceTypes.fromRows(Iterable<Map<dynamic, dynamic>> rows) {
    final byInterest = <String, List<InterestLink>>{};
    for (final row in rows) {
      final key = '${row['interest_key']}'.trim();
      final raw = '${row['place_type']}';
      if (key.isEmpty || raw.trim().isEmpty) continue;
      (byInterest[key] ??= []).add(
        InterestLink(
          PlaceType.of(raw).key,
          isPrimary: row['is_primary'] == true,
          scope: InterestCountyScope.parse(row['county_scope']),
        ),
      );
    }
    return InterestPlaceTypes(byInterest);
  }

  final Map<String, List<InterestLink>> _byInterest;

  bool get isEmpty => _byInterest.isEmpty;

  /// The first of [picks] (in the order picked) that [placeType] counts
  /// toward, or null when it matches none of them. [coastal] is whether the
  /// place's county is coastal; null when that is not known.
  PlaceInterest? matchFor(
    String placeType,
    Iterable<PlaceInterest> picks, {
    bool? coastal,
  }) {
    final type = PlaceType.of(placeType).key;
    for (final pick in picks) {
      final links = _byInterest[pick.key];
      if (links == null) continue;
      for (final link in links) {
        if (link.type == type && link.scope.covers(coastal: coastal)) {
          return pick;
        }
      }
    }
    return null;
  }

  /// The place types linked to [interest], whatever the county.
  Set<String> typesFor(PlaceInterest interest) => {
    for (final link in _byInterest[interest.key] ?? const <InterestLink>[])
      link.type,
  };

  /// Keys of every interest [placeType] is linked to.
  Set<String> interestKeysFor(String placeType) {
    final type = PlaceType.of(placeType).key;
    return {
      for (final entry in _byInterest.entries)
        if (entry.value.any((link) => link.type == type)) entry.key,
    };
  }

  static const _fallbackRows = <(String, String, bool, InterestCountyScope)>[
    ('nature', 'park', true, InterestCountyScope.any),
    ('nature', 'forest', true, InterestCountyScope.any),
    ('nature', 'garden', true, InterestCountyScope.any),
    ('nature', 'cave', true, InterestCountyScope.any),
    ('nature', 'mountain', true, InterestCountyScope.any),
    ('water', 'waterfall', true, InterestCountyScope.any),
    ('water', 'lake', true, InterestCountyScope.any),
    ('water', 'river', true, InterestCountyScope.any),
    ('water', 'hot_spring', true, InterestCountyScope.any),
    ('water', 'island', true, InterestCountyScope.inland),
    ('water', 'beach', true, InterestCountyScope.inland),
    ('activities', 'hike', true, InterestCountyScope.any),
    ('coast', 'beach', true, InterestCountyScope.coastal),
    ('coast', 'island', true, InterestCountyScope.coastal),
    ('coast', 'marine_park', true, InterestCountyScope.coastal),
    ('culture', 'museum', true, InterestCountyScope.any),
    ('culture', 'historic_site', true, InterestCountyScope.any),
    ('culture', 'monument', true, InterestCountyScope.any),
    ('culture', 'cultural_site', true, InterestCountyScope.any),
    ('culture', 'landmark', true, InterestCountyScope.any),
    ('wild', 'conservancy', true, InterestCountyScope.any),
    ('wild', 'park', false, InterestCountyScope.any),
    ('food', 'market', true, InterestCountyScope.any),
    ('food', 'food', true, InterestCountyScope.any),
    ('views', 'viewpoint', true, InterestCountyScope.any),
    ('views', 'desert', true, InterestCountyScope.any),
    ('views', 'mountain', false, InterestCountyScope.any),
    ('relax', 'stay', true, InterestCountyScope.any),
    ('relax', 'hot_spring', false, InterestCountyScope.any),
    ('relax', 'lake', false, InterestCountyScope.any),
  ];

  /// The bundled mapping (mirrors `20261018130000_interests_table.sql`).
  static final fallback = InterestPlaceTypes.fromRows([
    for (final (interest, type, primary, scope) in _fallbackRows)
      {
        'interest_key': interest,
        'place_type': type,
        'is_primary': primary,
        'county_scope': scope.name,
      },
  ]);
}
