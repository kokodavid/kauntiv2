/// Medal tiers by counties claimed (explored). Shared by Home and Badges
/// so the thresholds live in one place. There's no tier before the
/// first medal: the first badge is its own reward.
enum CountyTier {
  // The artwork files aren't numbered by tier: "Tier 2" is the bronze 10,
  // "Tier 1" the silver 25 and "Tier 3" the gold 47.
  msafiri(counties: 10, label: 'Msafiri', asset: 'assets/images/Tier 2.png'),
  mzururaji(
    counties: 25,
    label: 'Mzururaji',
    asset: 'assets/images/Tier 1.png',
  ),
  mkenyaHalisi(
    counties: 47,
    label: 'Mkenya Halisi',
    asset: 'assets/images/Tier 3.png',
  );

  const CountyTier({
    required this.counties,
    required this.label,
    required this.asset,
  });

  /// Counties claimed to earn it.
  final int counties;
  final String label;

  /// The medal artwork (90 x 107 PNG).
  final String asset;

  /// The highest tier earned with [claimed] counties; null before the
  /// first.
  static CountyTier? forClaimed(int claimed) {
    CountyTier? earned;
    for (final tier in values) {
      if (claimed >= tier.counties) earned = tier;
    }
    return earned;
  }

  /// The next tier to earn; null once all are earned.
  static CountyTier? nextAfter(int claimed) {
    for (final tier in values) {
      if (claimed < tier.counties) return tier;
    }
    return null;
  }
}
