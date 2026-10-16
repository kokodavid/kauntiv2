import 'explore_board.dart';
import 'explore_lists.dart';

/// One place with the county context Explore needs to filter and group it.
class ExploreEntry {
  const ExploreEntry({
    required this.place,
    required this.countyCode,
    required this.countyName,
    required this.claimed,
  });

  final ExplorePlace place;
  final int countyCode;
  final String countyName;

  /// Whether the traveller already holds this county's badge.
  final bool claimed;

  /// Straight-line distance in km, or null when there is no fix.
  double? get km {
    final meters = place.distanceMeters;
    return meters == null ? null : meters.toDouble() / 1000;
  }
}

/// Every place on the board once, with its county. Claimed counties come
/// first, then unclaimed, then saved-only groups.
List<ExploreEntry> exploreEntries(ExploreBoard board) {
  final result = <ExploreEntry>[];
  final seen = <String>{};

  void add(
    Iterable<ExplorePlace> places, {
    required int code,
    required String name,
    required bool claimed,
  }) {
    for (final place in places) {
      if (seen.add(place.id)) {
        result.add(
          ExploreEntry(
            place: place,
            countyCode: code,
            countyName: name,
            claimed: claimed,
          ),
        );
      }
    }
  }

  if (board.featuredUnlock case final unlock?) {
    add(
      unlock.catalogue,
      code: unlock.county.code,
      name: unlock.county.name,
      claimed: true,
    );
  }
  for (final county in board.mine) {
    add(
      county.catalogue,
      code: county.county.code,
      name: county.county.name,
      claimed: true,
    );
  }
  for (final county in board.unclaimed) {
    add(
      county.catalogue,
      code: county.county.code,
      name: county.county.name,
      claimed: false,
    );
  }
  for (final group in board.saved) {
    add(
      group.places,
      code: group.county.code,
      name: group.county.name,
      claimed:
          group.status == ExploreSavedStatus.badgeEarned ||
          group.status == ExploreSavedStatus.localExpert,
    );
  }
  return result;
}
