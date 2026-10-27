import 'badge_collection.dart';
import 'passport_county.dart';
import 'passport_level.dart';
import 'passport_regions.dart';
import 'passport_rules.dart';

/// Which counties the landing lists.
enum PassportFilter {
  all('All'),
  inProgress('In progress'),
  notStarted('Not started'),
  completed('Completed');

  const PassportFilter(this.label);

  final String label;

  bool matches(PassportCounty county) => switch (this) {
    all => true,
    inProgress => county.isInProgress,
    notStarted => !county.isStamped,
    completed => county.level == PassportLevel.gold,
  };
}

/// What the landing's "next stamp" card points at.
class PassportNextStamp {
  const PassportNextStamp({
    required this.county,
    required this.level,
    required this.isFirst,
  });

  /// Null for a brand-new traveller: "travel into any county".
  final PassportCounty? county;
  final PassportLevel level;
  final bool isFirst;
}

/// All 47 counties as Passport pages, in official county code order.
class PassportBook {
  PassportBook(
    List<PassportCounty> counties, {
    this.savedAt,
    this.firstStampAt,
    this.checkInsLive = false,
  }) : counties = _byCode(counties);

  static List<PassportCounty> _byCode(List<PassportCounty> counties) {
    final sorted = [...counties]..sort((a, b) => a.code.compareTo(b.code));
    return List<PassportCounty>.unmodifiable(sorted);
  }

  factory PassportBook.fromCollection(
    BadgeCollection collection, {
    PassportRules rules = PassportRules.standard,
  }) {
    final live = rules.withVerification(live: collection.checkInsLive);
    return PassportBook(
      [
        for (final badge in collection.badges)
          PassportCounty.fromBadge(
            badge,
            rules: live,
            checkIns: badge.checkIns,
          ),
      ],
      savedAt: collection.savedAt,
      firstStampAt: collection.firstStampAt,
      checkInsLive: collection.checkInsLive,
    );
  }

  final List<PassportCounty> counties;

  /// Set when this is the copy kept on the phone.
  final DateTime? savedAt;

  /// When the traveller's first stamp was earned; null when unknown.
  final DateTime? firstStampAt;

  /// Whether the server has check-ins on, so Bronze to Gold can be earned.
  final bool checkInsLive;

  bool get isSavedCopy => savedAt != null;

  int get total => counties.length;

  /// Counties with at least a Passed Through stamp.
  int get stampedCount => counties.where((c) => c.isStamped).length;

  /// Counties claimed: Explored or better. This is the same number the
  /// home map shows, so the app only ever has one "x of 47" for progress.
  int get claimedCount => counties
      .where((c) => c.level.index >= PassportLevel.explored.index)
      .length;

  int countAt(PassportLevel level) =>
      counties.where((c) => c.level == level).length;

  int countFor(PassportFilter filter) => counties.where(filter.matches).length;

  PassportCounty? byCode(int code) {
    for (final county in counties) {
      if (county.code == code) return county;
    }
    return null;
  }

  /// The levels of every county, highest first (the 47-segment bar).
  List<PassportLevel> get barLevels =>
      ([for (final c in counties) c.level]
        ..sort((a, b) => b.index.compareTo(a.index)));

  /// Counties by region (alphabetical, and alphabetical within each),
  /// narrowed by [filter] and [query]
  /// (a case-insensitive part of the name). Empty regions are left out.
  Map<PassportRegion, List<PassportCounty>> regions({
    PassportFilter filter = PassportFilter.all,
    String query = '',
  }) {
    final needle = query.trim().toLowerCase();
    final result = <PassportRegion, List<PassportCounty>>{};
    for (final region in PassportRegion.values) {
      final inRegion =
          counties
              .where(
                (c) =>
                    c.region == region &&
                    filter.matches(c) &&
                    (needle.isEmpty || c.name.toLowerCase().contains(needle)),
              )
              .toList()
            ..sort((a, b) => a.name.compareTo(b.name));
      if (inRegion.isNotEmpty) result[region] = inRegion;
    }
    return result;
  }

  /// Stamped counties in a region, for "x of y stamped".
  int stampedIn(PassportRegion region) => counties
      .where(
        (c) =>
            c.region == region && c.level.index >= PassportLevel.explored.index,
      )
      .length;

  int totalIn(PassportRegion region) =>
      counties.where((c) => c.region == region).length;

  /// A suggestion only: it never changes what anyone has earned. A
  /// brand-new traveller is told how the first stamp comes; otherwise a
  /// county passed through points at Explored.
  PassportNextStamp nextStamp() {
    if (stampedCount == 0) {
      return const PassportNextStamp(
        county: null,
        level: PassportLevel.passedThrough,
        isFirst: true,
      );
    }
    for (final county in counties) {
      if (county.level == PassportLevel.passedThrough) {
        return PassportNextStamp(
          county: county,
          level: PassportLevel.explored,
          isFirst: false,
        );
      }
    }
    for (final county in counties) {
      if (!county.isStamped) {
        return PassportNextStamp(
          county: county,
          level: PassportLevel.passedThrough,
          isFirst: false,
        );
      }
    }
    return PassportNextStamp(
      county: counties.first,
      level: PassportLevel.gold,
      isFirst: false,
    );
  }
}
