import '../../../core/domain/place_type.dart';
import '../../profile/domain/interest_matcher.dart';
import '../../profile/domain/place_interest.dart';
import '../domain/explore_entries.dart';

/// One place-type pill in the filter sheet: a place type, how many places it
/// has, and whether it matches one of the traveller's interests.
class ExploreDockType {
  const ExploreDockType({
    required this.type,
    required this.count,
    required this.isInterest,
  });

  final PlaceType type;
  final int count;
  final bool isInterest;
}

/// The filter sheet's type pills: every place type that has places, with the
/// traveller's interest types first (in catalog order), then the rest.
/// Types with no places are left out.
List<ExploreDockType> exploreDockTypes(
  List<ExploreEntry> entries,
  List<PlaceInterest> interests, {
  InterestMatcher? matcher,
}) {
  final rules = matcher ?? InterestMatcher.fallback;
  final counts = <String, int>{};
  final types = <String, PlaceType>{};
  for (final entry in entries) {
    final type = entry.place.category;
    counts[type.key] = (counts[type.key] ?? 0) + 1;
    types.putIfAbsent(type.key, () => type);
  }

  bool isInterest(PlaceType type) =>
      interests.isNotEmpty && rules.matchFor(type.key, interests) != null;

  final ordered = <PlaceType>[
    for (final type in PlaceType.all)
      if (counts.containsKey(type.key)) type,
    for (final type in types.values)
      if (!type.isListed) type,
  ];
  final first = [
    for (final type in ordered)
      if (isInterest(type)) type,
  ];
  final rest = [
    for (final type in ordered)
      if (!isInterest(type)) type,
  ];
  return [
    for (final type in [...first, ...rest])
      ExploreDockType(
        type: type,
        count: counts[type.key] ?? 0,
        isInterest: isInterest(type),
      ),
  ];
}
