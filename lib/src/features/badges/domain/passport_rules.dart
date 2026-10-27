import 'county_check_ins.dart';
import 'passport_level.dart';

/// What one metal level asks for, on top of the level before it.
class PassportMilestone {
  const PassportMilestone({
    required this.places,
    required this.categories,
    required this.visitDays,
  });

  /// Verified places, distinct categories among them, and distinct days the
  /// user was in the county.
  final int places;
  final int categories;
  final int visitDays;
}

/// Why a metal stamp can't be earned in a county yet: the county has fewer
/// reviewed places, or fewer categories among them, than the stamp asks for.
class PassportLock {
  const PassportLock({
    required this.level,
    required this.placesNeeded,
    required this.placesHave,
    required this.categoriesNeeded,
    required this.categoriesHave,
  });

  final PassportLevel level;
  final int placesNeeded;
  final int placesHave;
  final int categoriesNeeded;
  final int categoriesHave;

  bool get needsPlaces => placesHave < placesNeeded;
  bool get needsCategories => categoriesHave < categoriesNeeded;
}

/// The Passport's rules in one place. The app reads them from here and never
/// from a widget, so a dashboard can serve them later: swap [standard] for a
/// loaded copy and bump [version]. Nothing else needs to change.
class PassportRules {
  const PassportRules({
    required this.version,
    required this.exploredStay,
    required this.placeVerificationLive,
    required this.milestones,
  });

  final int version;

  /// One visit this long turns Passed Through into Explored. The same for
  /// everyone.
  final Duration exploredStay;

  /// False until place visits can be verified. While false, Bronze, Silver
  /// and Gold show as "Later" and nobody earns them from the app's own
  /// counts. Grandfathered levels still show.
  final bool placeVerificationLive;

  final Map<PassportLevel, PassportMilestone> milestones;

  PassportMilestone? milestoneFor(PassportLevel level) => milestones[level];

  /// The same rules with place verification switched on or off (the server
  /// decides, per environment).
  PassportRules withVerification({required bool live}) => PassportRules(
    version: version,
    exploredStay: exploredStay,
    placeVerificationLive: live,
    milestones: milestones,
  );

  /// What stops [level] being earned in a county yet: it needs more
  /// reviewed places, or places across more categories, than the county has.
  /// Null when the county can offer it, and null when the category count is
  /// unknown (not loaded), so a stamp is never locked on missing data.
  PassportLock? lockFor(
    PassportLevel level, {
    required int placesTotal,
    required int? categoriesTotal,
  }) {
    final m = milestones[level];
    if (m == null || categoriesTotal == null) return null;
    if (placesTotal >= m.places && categoriesTotal >= m.categories) return null;
    return PassportLock(
      level: level,
      placesNeeded: m.places,
      placesHave: placesTotal,
      categoriesNeeded: m.categories,
      categoriesHave: categoriesTotal,
    );
  }

  /// The highest metal stamp [checkIns] reaches, or null for none. Only
  /// meaningful while [placeVerificationLive]. The targets are the same in
  /// every county, so a stamp earned stays earned when places are added.
  PassportLevel? metalFor(CountyCheckIns checkIns) {
    if (!placeVerificationLive) return null;
    PassportLevel? best;
    for (final level in const [
      PassportLevel.bronze,
      PassportLevel.silver,
      PassportLevel.gold,
    ]) {
      final m = milestones[level];
      if (m == null) continue;
      if (checkIns.places >= m.places &&
          checkIns.categories >= m.categories &&
          checkIns.visitDays >= m.visitDays) {
        best = level;
      } else {
        break;
      }
    }
    return best;
  }

  static const standard = PassportRules(
    version: 1,
    exploredStay: Duration(hours: 2),
    placeVerificationLive: false,
    milestones: {
      PassportLevel.bronze: PassportMilestone(
        places: 3,
        categories: 2,
        visitDays: 1,
      ),
      PassportLevel.silver: PassportMilestone(
        places: 6,
        categories: 3,
        visitDays: 2,
      ),
      PassportLevel.gold: PassportMilestone(
        places: 10,
        categories: 4,
        visitDays: 3,
      ),
    },
  );
}
