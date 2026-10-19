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

  /// What [level] asks for in a county with [placesTotal] reviewed places: a
  /// county with fewer places than the standard asks for lowers its target
  /// to what it has, so it can still be completed.
  ({int places, int categories, int visitDays})? targetsFor(
    PassportLevel level,
    int placesTotal,
  ) {
    final m = milestones[level];
    if (m == null) return null;
    final places = placesTotal > 0 && placesTotal < m.places
        ? placesTotal
        : m.places;
    final categories = m.categories > places ? places : m.categories;
    return (places: places, categories: categories, visitDays: m.visitDays);
  }

  /// The highest metal stamp [checkIns] reaches, or null for none. Only
  /// meaningful while [placeVerificationLive].
  PassportLevel? metalFor(CountyCheckIns checkIns) {
    if (!placeVerificationLive) return null;
    PassportLevel? best;
    for (final level in const [
      PassportLevel.bronze,
      PassportLevel.silver,
      PassportLevel.gold,
    ]) {
      final t = targetsFor(level, checkIns.placesTotal);
      if (t == null) continue;
      if (checkIns.places >= t.places &&
          checkIns.categories >= t.categories &&
          checkIns.visitDays >= t.visitDays) {
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
