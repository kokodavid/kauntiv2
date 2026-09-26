/// Medal tiers by counties claimed (explored). Shared by Home and Badges
/// so the thresholds live in one place. There's no tier before the
/// first medal: the first badge is its own reward.
enum CountyTier {
  msafiri(counties: 10, label: 'Msafiri', number: 1),
  mzururaji(counties: 25, label: 'Mzururaji', number: 2),
  mkenyaHalisi(counties: 47, label: 'Mkenya Halisi', number: 3);

  const CountyTier({
    required this.counties,
    required this.label,
    required this.number,
  });

  /// Counties claimed to earn it.
  final int counties;
  final String label;

  /// 1-3, as the medal artwork is numbered.
  final int number;

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
