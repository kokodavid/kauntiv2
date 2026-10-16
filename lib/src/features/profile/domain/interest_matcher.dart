import 'interest_place_types.dart';
import 'place_interest.dart';

/// Which counties are coastal, from `counties.is_coastal`. Unknown until
/// loaded, and then every county scope counts.
class CountyCoast {
  const CountyCoast(this._codes);

  static const unknown = CountyCoast(null);

  final Set<int>? _codes;

  /// Whether county [code] is coastal; null when not known.
  bool? isCoastal(int? code) {
    final codes = _codes;
    if (codes == null || code == null) return null;
    return codes.contains(code);
  }
}

/// Decides which of a traveller's interests a place counts toward: its type
/// (from the backend mapping) and its county (Coast only counts in coastal
/// counties, lake islands count as Water).
class InterestMatcher {
  const InterestMatcher(this.types, this.coast);

  /// The bundled mapping, with county status unknown: tests and first launch.
  static final fallback = InterestMatcher(
    InterestPlaceTypes.fallback,
    CountyCoast.unknown,
  );

  final InterestPlaceTypes types;
  final CountyCoast coast;

  PlaceInterest? matchFor(
    String placeType,
    Iterable<PlaceInterest> picks, {
    int? countyCode,
  }) => types.matchFor(placeType, picks, coastal: coast.isCoastal(countyCode));
}
