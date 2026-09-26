import '../../../core/domain/county_tier.dart';
import '../../../counties/county_paths.dart';
import '../../map_home/domain/county_badge_state.dart';

/// How deep someone's knowledge of a county goes (docs 02: the depth
/// ladder). Drawn as the ring round each badge, a quarter per level.
enum CountyDepth {
  none,
  passedThrough,
  visited,
  regular,
  localExpert;

  /// Quarters of the ring filled: 0 (none) to 4 (local expert).
  int get quarters => index;

  String get label => switch (this) {
    none => 'Not yet',
    passedThrough => 'Passed through',
    visited => 'Visited',
    regular => 'Regular',
    localExpert => 'Local expert',
  };

  /// `county_depth_ranks()`'s rank for an explored county.
  static CountyDepth fromRank(String? rank) => switch (rank) {
    'local_expert' => localExpert,
    'regular' => regular,
    _ => visited,
  };
}

/// One county's badge.
class CountyBadge {
  const CountyBadge({
    required this.county,
    required this.state,
    required this.depth,
  });

  final CountyPath county;
  final CountyBadgeState state;
  final CountyDepth depth;

  bool get isEarned => state == CountyBadgeState.earned;
}

/// Every county's badge: earned ones first, then the rest, each in county
/// code order.
class BadgeCollection {
  BadgeCollection(List<CountyBadge> badges)
    : badges = [
        ...badges.where((b) => b.isEarned),
        ...badges.where((b) => !b.isEarned),
      ];

  /// From `county_visits` states and `county_depth_ranks()` ranks, both by
  /// county code. Counties with no visit are locked.
  factory BadgeCollection.from({
    required Map<int, String> visitStates,
    required Map<int, String> ranks,
  }) {
    final counties = [...CountyPaths.all]
      ..sort((a, b) => a.code.compareTo(b.code));
    return BadgeCollection([
      for (final county in counties)
        _badge(county, visitStates[county.code], ranks[county.code]),
    ]);
  }

  static CountyBadge _badge(CountyPath county, String? visit, String? rank) {
    final (state, depth) = switch (visit) {
      'explored' => (CountyBadgeState.earned, CountyDepth.fromRank(rank)),
      'passed_through' => (
        CountyBadgeState.passedThrough,
        CountyDepth.passedThrough,
      ),
      'pending' => (CountyBadgeState.pending, CountyDepth.none),
      _ => (CountyBadgeState.locked, CountyDepth.none),
    };
    return CountyBadge(county: county, state: state, depth: depth);
  }

  final List<CountyBadge> badges;

  int get total => CountyPaths.all.length;
  int get claimed => badges.where((b) => b.isEarned).length;
  int get left => total - claimed;

  /// Whole percent of Kenya's counties claimed, rounded down.
  int get percentOfKenya => total == 0 ? 0 : claimed * 100 ~/ total;

  /// The medal earned so far; null before the first (10 counties).
  CountyTier? get tier => CountyTier.forClaimed(claimed);

  /// The next medal to go for; null once all three are earned.
  CountyTier? get nextTier => CountyTier.nextAfter(claimed);
}
