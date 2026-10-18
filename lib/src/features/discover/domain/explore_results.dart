import '../../../core/domain/place_type.dart';
import '../../profile/domain/interest_matcher.dart';
import '../../profile/domain/place_interest.dart';
import 'explore_entries.dart';
import 'explore_filters.dart';

/// A run of results in one distance band, nearest first.
class ExploreBand {
  const ExploreBand({required this.label, required this.entries});

  /// "UNDER 100 KM", "100 - 150 KM"; empty when there is no distance data.
  final String label;
  final List<ExploreEntry> entries;
}

/// Filtered places grouped by distance, plus what lies beyond the limit.
class ExploreResults {
  const ExploreResults({
    required this.bands,
    required this.count,
    required this.furtherCount,
    required this.nextStopKm,
    this.closest = const [],
  });

  final List<ExploreBand> bands;
  final int count;

  /// Places that match everything except the distance limit.
  final int furtherCount;

  /// The next slider stop past the limit; null means "show all".
  final int? nextStopKm;

  /// When the distance limit leaves nothing: the nearest place that breaks
  /// only that limit.
  final List<ExploreEntry> closest;
}

/// Filters [all], sorts nearest first and groups into distance bands.
/// Without a location fix ([hasLocation] false) there is one unlabelled band.
ExploreResults buildExploreResults(
  List<ExploreEntry> all,
  ExploreFilters filters, {
  required bool hasLocation,
}) {
  final matches = all.where(filters.matches).toList();
  final sorted = matches.indexed.toList()
    ..sort((a, b) {
      final ka = a.$2.km;
      final kb = b.$2.km;
      if (ka == null && kb == null) return a.$1.compareTo(b.$1);
      if (ka == null) return 1;
      if (kb == null) return -1;
      final byKm = ka.compareTo(kb);
      return byKm != 0 ? byKm : a.$1.compareTo(b.$1);
    });
  final entries = [for (final (_, entry) in sorted) entry];

  final maxKm = filters.maxKm;
  var further = 0;
  int? nextStop;
  if (maxKm != null) {
    final withoutLimit = filters.copyWith(clearMaxKm: true);
    further = all.where((entry) {
      final km = entry.km;
      return km != null && km > maxKm && withoutLimit.matches(entry);
    }).length;
    for (final stop in ExploreFilters.distanceStops) {
      if (stop > maxKm) {
        nextStop = stop;
        break;
      }
    }
  }

  var closest = const <ExploreEntry>[];
  if (maxKm != null && entries.isEmpty) {
    final withoutLimit = filters.copyWith(clearMaxKm: true);
    closest = [
      for (final entry in all)
        if (entry.km != null && withoutLimit.matches(entry)) entry,
    ]..sort((a, b) => a.km!.compareTo(b.km!));
    closest = closest.take(1).toList();
  }

  return ExploreResults(
    bands: hasLocation ? _bands(entries, maxKm) : _flat(entries),
    count: entries.length,
    furtherCount: further,
    nextStopKm: nextStop,
    closest: closest,
  );
}

List<ExploreBand> _flat(List<ExploreEntry> entries) =>
    entries.isEmpty ? const [] : [ExploreBand(label: '', entries: entries)];

List<ExploreBand> _bands(List<ExploreEntry> entries, int? maxKm) {
  const edges = ExploreFilters.distanceStops;
  final grouped = List.generate(edges.length + 1, (_) => <ExploreEntry>[]);
  final unknown = <ExploreEntry>[];
  for (final entry in entries) {
    final km = entry.km;
    if (km == null) {
      unknown.add(entry);
      continue;
    }
    var index = edges.indexWhere((edge) => km < edge);
    if (index == -1) index = edges.length;
    grouped[index].add(entry);
  }

  final bands = <ExploreBand>[];
  for (var i = 0; i < grouped.length; i++) {
    if (grouped[i].isEmpty) continue;
    final lower = i == 0 ? 0 : edges[i - 1];
    final upper = i < edges.length ? edges[i] : null;
    final cap = upper == null
        ? maxKm
        : (maxKm != null && maxKm < upper ? maxKm : upper);
    final String label;
    if (bands.isEmpty) {
      label = cap != null ? 'UNDER $cap KM' : 'OVER $lower KM';
    } else {
      label = cap != null ? '$lower - $cap KM' : '$lower+ KM';
    }
    bands.add(ExploreBand(label: label, entries: grouped[i]));
  }
  if (unknown.isNotEmpty) {
    bands.add(ExploreBand(label: 'NO DISTANCE', entries: unknown));
  }
  return bands;
}

const _nounOverrides = {
  'cultural_site': ('cultural site', 'cultural sites'),
  'viewpoint': ('viewpoint', 'viewpoints'),
  'food': ('food spot', 'food spots'),
};

/// "waterfalls", "1 hike" style noun for a count sentence.
String exploreNoun(String? typeKey, int count) {
  if (typeKey == null) return count == 1 ? 'place' : 'places';
  final override = _nounOverrides[typeKey];
  if (override != null) return count == 1 ? override.$1 : override.$2;
  final type = PlaceType.of(typeKey);
  return (count == 1 ? type.label : type.pluralLabel).toLowerCase();
}

/// The results sentence split for styling: the accent [lead] ("3 waterfalls")
/// and the plain [tail] (" in counties you haven't claimed").
({String lead, String tail}) exploreSentence(
  ExploreFilters filters,
  int count, {
  String? countyName,
}) {
  final lead = '$count ${exploreNoun(filters.typeKey, count)}';
  final tail = filters.unclaimedOnly
      ? " in counties you haven't claimed"
      : filters.countyCode != null && countyName != null
      ? ' in $countyName'
      : filters.maxKm != null
      ? ' within ${filters.maxKm} km of you'
      : '';
  return (lead: lead, tail: tail);
}

/// Types related to [typeKey] (they share an interest with it) that have
/// places, most places first, at most two: "Similar places" under a thin
/// category.
List<({PlaceType type, int count})> exploreSimilarTypes(
  List<ExploreEntry> entries,
  String typeKey, {
  InterestMatcher? matcher,
}) {
  final rules = matcher ?? InterestMatcher.fallback;
  final counts = <String, int>{};
  for (final entry in entries) {
    final key = entry.place.category.key;
    counts[key] = (counts[key] ?? 0) + 1;
  }
  // The interests [typeKey] belongs to, by key so a backend-added one counts.
  final interests = [
    for (final key in rules.types.interestKeysFor(typeKey))
      PlaceInterest.fromKey(key) ?? PlaceInterest.unlisted(key),
  ];
  final similar = [
    for (final entry in counts.entries)
      if (entry.key != typeKey && rules.matchFor(entry.key, interests) != null)
        (type: PlaceType.of(entry.key), count: entry.value),
  ]..sort((a, b) => b.count.compareTo(a.count));
  return similar.take(2).toList();
}

/// For each interest, the place types that have places on the board: what a
/// "For you" filter chip stands for. Interests with no places are left out.
Map<PlaceInterest, Set<String>> exploreInterestTypes(
  List<ExploreEntry> entries,
  List<PlaceInterest> interests, {
  InterestMatcher? matcher,
}) {
  final rules = matcher ?? InterestMatcher.fallback;
  final result = <PlaceInterest, Set<String>>{};
  for (final interest in interests) {
    final keys = {
      for (final entry in entries)
        if (rules.matchFor(entry.place.category.key, [
              interest,
            ], countyCode: entry.countyCode) !=
            null)
          entry.place.category.key,
    };
    if (keys.isNotEmpty) result[interest] = keys;
  }
  return result;
}
