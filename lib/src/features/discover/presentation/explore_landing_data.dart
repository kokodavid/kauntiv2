import '../../profile/domain/interest_matcher.dart';
import '../../profile/domain/place_interest.dart';
import '../domain/explore_board.dart';
import '../domain/explore_entries.dart';
import '../domain/explore_headline.dart';
import 'explore_go_back.dart';
import 'explore_interest_chapters.dart';

/// Everything the Places landing derives from the board: the lead sentence,
/// each chapter's places, and the groupings behind them.
///
/// It is built once per set of inputs and kept (see the landing's cache), so
/// rebuilding the page for an unrelated reason, like an animation tick up
/// the tree, never re-sorts and re-matches every place again.
class ExploreLandingData {
  const ExploreLandingData._({
    required this.entries,
    required this.goBack,
    required this.nextLead,
    required this.nextBadge,
    required this.homePlaces,
    required this.headline,
    required this.headlineRow,
    required this.forYou,
    required this.more,
  });

  factory ExploreLandingData.build({
    required ExploreBoard board,
    required List<PlaceInterest> interests,
    required InterestMatcher matcher,
    required List<ExploreEntry> nearby,
    required int rotation,
    required bool locationUnavailable,
    required String? homeCountyName,
  }) {
    // Places in counties not yet claimed first, then the rest.
    final all = exploreEntries(board);
    final entries = [
      ...all.where((entry) => !entry.claimed),
      ...all.where((entry) => entry.claimed),
    ];

    // "Next badge": places in counties not yet claimed, nearest first. With
    // claimed counties the first place leads; without a location it names
    // the home county instead (design frames 1b and 4d).
    final unclaimed = [
      for (final e in entries)
        if (!e.claimed) e,
    ];
    final allClaimed = board.unclaimedCount == 0 && board.mineCount > 0;
    final goBack = allClaimed
        ? exploreGoBackPlaces(board, entries).take(6).toList()
        : const <ExploreEntry>[];
    final claimedAny = board.mineCount > 0;
    final nextLead = claimedAny && !locationUnavailable
        ? unclaimed.where((e) => e.place.thumbnailUrl != null).firstOrNull
        : null;
    final nextBadge = locationUnavailable || claimedAny
        ? [
            for (final e in unclaimed)
              if (e != nextLead) e,
          ].take(6).toList()
        : const <ExploreEntry>[];

    final homePlaces = homeCountyName == null || nearby.isNotEmpty
        ? const <ExploreEntry>[]
        : [
            for (final e in entries)
              if (e.countyName == homeCountyName) e,
          ].take(6).toList();

    final headline = exploreHeadline(
      board: board,
      entries: entries,
      interests: interests,
      locationUnavailable: locationUnavailable,
      homeCountyName: homeCountyName,
      rotation: rotation,
      matcher: matcher,
    );
    // The row straight under a "3 waterfalls within 100 km" sentence is
    // exactly those places, so the title and the cards always agree.
    final headlineRow = switch (headline.typeKey) {
      final key? => exploreHeadlinePlaces(
        entries,
        key,
        withinRadius: headline.withinRadius,
        interests: interests,
        matcher: matcher,
      ),
      null => const <ExploreEntry>[],
    };

    final shownAbove = {for (final e in headlineRow) e.place.id};
    final forYou =
        <({ExploreInterestChapter group, List<ExploreEntry> places})>[
          for (final group in exploreInterestChapters(
            entries,
            interests,
            matcher: matcher,
            hide: shownAbove,
          ))
            (group: group, places: group.places),
        ];
    // What For you did not cover, by type: no repeats, none hidden.
    final more = exploreTypeChapters(
      exploreUnmatched(entries, interests, matcher),
    );

    return ExploreLandingData._(
      entries: entries,
      goBack: goBack,
      nextLead: nextLead,
      nextBadge: nextBadge,
      homePlaces: homePlaces,
      headline: headline,
      headlineRow: headlineRow,
      forYou: forYou,
      more: more,
    );
  }

  final List<ExploreEntry> entries;
  final List<ExploreEntry> goBack;
  final ExploreEntry? nextLead;
  final List<ExploreEntry> nextBadge;
  final List<ExploreEntry> homePlaces;
  final ExploreHeadline headline;
  final List<ExploreEntry> headlineRow;

  /// Interest chapters with the headline's places already taken out.
  final List<({ExploreInterestChapter group, List<ExploreEntry> places})>
  forYou;
  final List<ExploreTypeChapter> more;
}
