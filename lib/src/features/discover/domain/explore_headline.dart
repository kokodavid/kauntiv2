import '../../../counties/county_paths.dart';
import '../../profile/domain/interest_matcher.dart';
import '../../profile/domain/place_interest.dart';
import 'explore_board.dart';
import 'explore_entries.dart';
import 'explore_results.dart';

/// The places a "N waterfalls within R km" sentence counts, nearest first.
/// With [withinRadius] false (the "nearest beach is 480 km away" sentence)
/// the radius does not apply and the first six are returned.
List<ExploreEntry> exploreHeadlinePlaces(
  List<ExploreEntry> entries,
  String typeKey, {
  bool withinRadius = true,
  List<PlaceInterest> interests = const [],
  InterestMatcher? matcher,
}) {
  final rules = matcher ?? InterestMatcher.fallback;
  final found = [
    for (final entry in entries)
      if (entry.place.category.key == typeKey &&
          (interests.isEmpty ||
              rules.matchFor(
                    typeKey,
                    interests,
                    countyCode: entry.countyCode,
                  ) !=
                  null) &&
          entry.km != null &&
          (!withinRadius || entry.km! <= exploreHeadlineRadiusKm))
        entry,
  ]..sort((a, b) => a.km!.compareTo(b.km!));
  return withinRadius ? found : found.take(6).toList();
}

/// Radius for the "N waterfalls within R km of you" sentence.
const exploreHeadlineRadiusKm = 100;

/// The Places landing sentence (Explore Field Guide v2): [before], the
/// accent [accent] phrase, then [after].
class ExploreHeadline {
  const ExploreHeadline({
    required this.before,
    required this.accent,
    required this.after,
    this.typeKey,
    this.withinRadius = true,
  });

  final String before;
  final String accent;
  final String after;

  /// The place type the sentence counts, when it counts one ("3 waterfalls").
  /// The cards under the sentence must be exactly those places.
  final String? typeKey;

  /// False when the sentence names a place beyond the radius, so the cards
  /// are that type's nearest places at any distance.
  final bool withinRadius;

  String get text => '$before$accent$after';
}

/// Picks the sentence for the traveller's state, most specific first:
/// everything claimed, location off, a next badge to head for, then the
/// nearest of what they like, then a plain count of counties left. With
/// several liked types nearby, [rotation] (one more each app launch) takes
/// them in turn, so the sentence does not always lead with the same one.
ExploreHeadline exploreHeadline({
  required ExploreBoard board,
  required List<ExploreEntry> entries,
  required List<PlaceInterest> interests,
  required bool locationUnavailable,
  String? homeCountyName,
  int rotation = 0,
  InterestMatcher? matcher,
}) {
  final rules = matcher ?? InterestMatcher.fallback;
  final claimed = board.mineCount;
  final total = claimed + board.unclaimed.length;

  if (total > 0 && board.unclaimed.isEmpty) {
    final last = exploreLastVisited(board);
    return ExploreHeadline(
      before: 'All ',
      accent: '$total',
      after: last == null
          ? ' claimed.'
          : ' claimed. You last visited ${last.county.name} in '
                '${exploreMonthYear(last.at)}.',
    );
  }
  if (locationUnavailable && homeCountyName != null) {
    return ExploreHeadline(
      before: 'Starting from ',
      accent: homeCountyName,
      after: ', your home county.',
    );
  }
  // Parked until we decide on the "next badge" sentence (it came with a
  // progress bar, now removed):
  //   if (claimed > 0) {
  //     final next = _nearestUnclaimed(board);
  //     if (next != null) {
  //       return ExploreHeadline(
  //         before: 'Your next badge is ',
  //         accent: next.name,
  //         after: ', ${next.km} km away.',
  //         progress: claimed / total,
  //         progressLabel: '$claimed of $total claimed',
  //       );
  //     }
  //   }

  final near = _nearestOfInterests(entries, interests, rotation, rules);
  if (near == null) {
    final far = _nearestLikedPlace(entries, interests, rotation, rules);
    if (far != null) {
      return ExploreHeadline(
        before: 'Nearest ${exploreNoun(far.typeKey, 1)} is ',
        accent: far.place.place.title,
        after: ', ${far.place.km!.round()} km away.',
        typeKey: far.typeKey,
        withinRadius: false,
      );
    }
  }
  if (near != null) {
    return ExploreHeadline(
      before: '',
      accent: near.label,
      typeKey: near.typeKey,
      after:
          ' within $exploreHeadlineRadiusKm km of you.'
          '${claimed == 0 ? ' All $total counties still to claim.' : ''}',
    );
  }
  return ExploreHeadline(
    before: '',
    accent: '${total - claimed} counties',
    after: ' still to claim.',
  );
}

// Parked with the "next badge" sentence above.
// ({String name, int km})? _nearestUnclaimed(ExploreBoard board) {
//   ({String name, int km})? best;
//   num? bestMeters;
//   for (final county in board.unclaimed) {
//     final meters = county.distanceMeters;
//     if (meters == null) continue;
//     if (bestMeters == null || meters < bestMeters) {
//       bestMeters = meters;
//       best = (name: county.county.name, km: (meters / 1000).round());
//     }
//   }
//   return best;
// }

/// "4 waterfalls": one liked type with places inside the radius, and its
/// key. Types are ordered most places first, then nearest, then by key, and
/// [rotation] walks that list, so a given launch is stable.
({String label, String typeKey})? _nearestOfInterests(
  List<ExploreEntry> entries,
  List<PlaceInterest> interests,
  int rotation,
  InterestMatcher rules,
) {
  if (interests.isEmpty) return null;
  final counts = <String, int>{};
  final nearest = <String, double>{};
  for (final entry in entries) {
    final km = entry.km;
    if (km == null || km > exploreHeadlineRadiusKm) continue;
    final key = entry.place.category.key;
    if (rules.matchFor(key, interests, countyCode: entry.countyCode) == null) {
      continue;
    }
    counts[key] = (counts[key] ?? 0) + 1;
    if (km < (nearest[key] ?? double.infinity)) nearest[key] = km;
  }
  if (counts.isEmpty) return null;
  final ordered = counts.keys.toList()
    ..sort((a, b) {
      final byCount = counts[b]!.compareTo(counts[a]!);
      if (byCount != 0) return byCount;
      final byDistance = nearest[a]!.compareTo(nearest[b]!);
      return byDistance != 0 ? byDistance : a.compareTo(b);
    });
  final key = ordered[rotation.abs() % ordered.length];
  return (
    label: '${counts[key]} ${exploreNoun(key, counts[key]!)}',
    typeKey: key,
  );
}

/// When nothing liked is inside the radius: the nearest place of a liked
/// type, taking the types in turn by how near each is, so the sentence still
/// speaks to what the traveller likes. Null with no interests or no fix.
({String typeKey, ExploreEntry place})? _nearestLikedPlace(
  List<ExploreEntry> entries,
  List<PlaceInterest> interests,
  int rotation,
  InterestMatcher rules,
) {
  if (interests.isEmpty) return null;
  final nearest = <String, ExploreEntry>{};
  for (final entry in entries) {
    final km = entry.km;
    if (km == null) continue;
    final key = entry.place.category.key;
    if (rules.matchFor(key, interests, countyCode: entry.countyCode) == null) {
      continue;
    }
    final best = nearest[key];
    if (best == null || km < best.km!) nearest[key] = entry;
  }
  if (nearest.isEmpty) return null;
  final ordered = nearest.entries.toList()
    ..sort((a, b) {
      final byKm = a.value.km!.compareTo(b.value.km!);
      return byKm != 0 ? byKm : a.key.compareTo(b.key);
    });
  final pick = ordered[rotation.abs() % ordered.length];
  return (typeKey: pick.key, place: pick.value);
}

/// The claimed county visited most recently, when the dates are known.
({CountyPath county, DateTime at})? exploreLastVisited(ExploreBoard board) {
  ({CountyPath county, DateTime at})? best;
  void consider(CountyPath county, DateTime? at) {
    if (at == null) return;
    if (best == null || at.isAfter(best!.at)) best = (county: county, at: at);
  }

  if (board.featuredUnlock case final unlock?) {
    consider(unlock.county, unlock.lastVisitedAt);
  }
  for (final entry in board.mine) {
    consider(entry.county, entry.lastVisitedAt);
  }
  return best;
}

/// "Dec 2024".
String exploreMonthYear(DateTime date) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${months[date.month - 1]} ${date.year}';
}
