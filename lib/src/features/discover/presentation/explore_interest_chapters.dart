import '../../../core/domain/place_type.dart';
import '../../profile/domain/interest_matcher.dart';
import '../../profile/domain/place_interest.dart';
import '../domain/explore_entries.dart';

/// A "For you" chapter: up to six places for one chosen interest, with how
/// many there are in all and which place types they span (for "See all").
class ExploreInterestChapter {
  const ExploreInterestChapter(
    this.interest,
    this.places, {
    required this.total,
    required this.typeKeys,
  });

  final PlaceInterest interest;
  final List<ExploreEntry> places;
  final int total;
  final Set<String> typeKeys;
}

/// One chapter per chosen interest that has places. A place counts toward
/// the first interest (in the order given) it matches and is never listed
/// again under a later one, so nothing repeats.
///
/// Places in [hide] (already shown in a row above) are left out of the cards
/// *before* the six are picked, so the chapter still fills its row; [total]
/// keeps counting them, so "See all" matches what that list opens.
List<ExploreInterestChapter> exploreInterestChapters(
  List<ExploreEntry> entries,
  List<PlaceInterest> interests, {
  InterestMatcher? matcher,
  Set<String> hide = const {},
}) {
  final rules = matcher ?? InterestMatcher.fallback;
  final chapters = <ExploreInterestChapter>[];
  final listed = <String>{};
  for (final interest in interests) {
    final matching = [
      for (final entry in entries)
        if (!listed.contains(entry.place.id) &&
            rules.matchFor(entry.place.category.key, [
                  interest,
                ], countyCode: entry.countyCode) !=
                null)
          entry,
    ];
    if (matching.isEmpty) continue;
    listed.addAll(matching.map((e) => e.place.id));
    final cards = [
      for (final e in matching)
        if (!hide.contains(e.place.id)) e,
    ];
    if (cards.isEmpty) continue;
    chapters.add(
      ExploreInterestChapter(
        interest,
        cards.take(6).toList(),
        total: matching.length,
        typeKeys: {for (final e in matching) e.place.category.key},
      ),
    );
  }
  return chapters;
}

/// The places that match none of [interests]: what "More places" lists, so
/// a place under a For you chapter is never hidden and never repeated.
List<ExploreEntry> exploreUnmatched(
  List<ExploreEntry> entries,
  List<PlaceInterest> interests,
  InterestMatcher matcher,
) => [
  for (final e in entries)
    if (matcher.matchFor(
          e.place.category.key,
          interests,
          countyCode: e.countyCode,
        ) ==
        null)
      e,
];

/// A chapter for one place type, for travellers with no interests yet: up to
/// six places and how many there are in all.
class ExploreTypeChapter {
  const ExploreTypeChapter(this.type, this.places, {required this.total});

  final PlaceType type;
  final List<ExploreEntry> places;
  final int total;
}

/// One chapter per place type, the type with the most places first, leaving
/// out the types in [exclude] (already shown above), so every place is
/// reachable and none repeats.
List<ExploreTypeChapter> exploreTypeChapters(
  List<ExploreEntry> entries, {
  Set<String> exclude = const {},
}) {
  final byType = <String, List<ExploreEntry>>{};
  for (final entry in entries) {
    if (exclude.contains(entry.place.category.key)) continue;
    (byType[entry.place.category.key] ??= []).add(entry);
  }
  final chapters =
      [
        for (final group in byType.values)
          ExploreTypeChapter(
            group.first.place.category,
            group.take(6).toList(),
            total: group.length,
          ),
      ]..sort((a, b) {
        final byCount = b.total.compareTo(a.total);
        return byCount != 0
            ? byCount
            : a.type.pluralLabel.compareTo(b.type.pluralLabel);
      });
  return chapters;
}
