import 'package:flutter_test/flutter_test.dart';
import 'package:kaunti47_v2/src/core/domain/county_tier.dart';
import 'package:kaunti47_v2/src/features/badges/domain/badge_collection.dart';
import 'package:kaunti47_v2/src/features/map_home/domain/county_badge_state.dart';

void main() {
  // 47 Nairobi, 22 Kiambu, 1 Mombasa, 30 Baringo, 10 Marsabit.
  final collection = BadgeCollection.from(
    visitStates: {
      47: 'explored',
      22: 'explored',
      1: 'explored',
      30: 'passed_through',
      10: 'pending',
    },
    ranks: {47: 'local_expert', 22: 'regular'},
  );

  CountyBadge badge(int code) =>
      collection.badges.firstWhere((b) => b.county.code == code);

  test('counts, share of Kenya and tier', () {
    expect(collection.total, 47);
    expect(collection.claimed, 3);
    expect(collection.left, 44);
    expect(collection.percentOfKenya, 6); // 3/47 = 6.4%
    // 3 claimed: no medal yet; Msafiri comes at 10.
    expect(collection.tier, isNull);
    expect(collection.nextTier, CountyTier.msafiri);
  });

  test('state and depth per county', () {
    expect(badge(47).state, CountyBadgeState.earned);
    expect(badge(47).depth, CountyDepth.localExpert);
    expect(badge(22).depth, CountyDepth.regular);
    // Explored without a rank yet: visited.
    expect(badge(1).depth, CountyDepth.visited);
    expect(badge(30).state, CountyBadgeState.passedThrough);
    expect(badge(30).depth.quarters, 1);
    expect(badge(10).state, CountyBadgeState.pending);
    expect(badge(10).depth, CountyDepth.none);
    expect(badge(2).state, CountyBadgeState.locked);
  });

  test('earned badges come first, each group in county order', () {
    expect(collection.badges, hasLength(47));
    expect(collection.badges.take(3).map((b) => b.county.code), [1, 22, 47]);
    expect(collection.badges[3].county.code, 2);
  });

  test('medals at 10, 25 and 47 counties', () {
    expect(CountyTier.forClaimed(0), isNull);
    expect(CountyTier.forClaimed(9), isNull);
    expect(CountyTier.forClaimed(10), CountyTier.msafiri);
    expect(CountyTier.forClaimed(24), CountyTier.msafiri);
    expect(CountyTier.forClaimed(25), CountyTier.mzururaji);
    expect(CountyTier.forClaimed(47), CountyTier.mkenyaHalisi);
    expect(CountyTier.nextAfter(9), CountyTier.msafiri);
    expect(CountyTier.nextAfter(10), CountyTier.mzururaji);
    expect(CountyTier.nextAfter(47), isNull);
  });
}
