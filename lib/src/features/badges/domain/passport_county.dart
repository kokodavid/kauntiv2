import '../../../counties/county_paths.dart';
import '../../map_home/domain/county_badge_state.dart';
import 'badge_collection.dart';
import 'county_check_ins.dart';
import 'passport_level.dart';
import 'passport_regions.dart';
import 'passport_rules.dart';

/// One county's page: where it stands and what it is.
class PassportCounty {
  const PassportCounty({required this.county, required this.level});

  /// Reads a badge as a Passport level. Explored counties that already had
  /// depth keep it as a metal: Regular is Bronze and Local expert is Silver,
  /// so nobody loses standing. Nobody is moved down.
  ///
  /// With place verification live, check-ins can lift an Explored county to
  /// Bronze, Silver or Gold by [rules]; a county never drops below what the
  /// older depth or its own stay already gave it.
  factory PassportCounty.fromBadge(
    CountyBadge badge, {
    PassportRules rules = PassportRules.standard,
    CountyCheckIns checkIns = CountyCheckIns.none,
  }) {
    final level = switch (badge.state) {
      CountyBadgeState.earned => switch (badge.depth) {
        CountyDepth.localExpert => PassportLevel.silver,
        CountyDepth.regular => PassportLevel.bronze,
        _ => PassportLevel.explored,
      },
      CountyBadgeState.passedThrough => PassportLevel.passedThrough,
      _ => PassportLevel.none,
    };
    final earned = level.index < PassportLevel.explored.index
        ? null
        : rules.metalFor(checkIns);
    return PassportCounty(
      county: badge.county,
      level: earned != null && earned.index > level.index ? earned : level,
    );
  }

  final CountyPath county;
  final PassportLevel level;

  int get code => county.code;
  String get name => county.name;
  PassportRegion get region => PassportRegion.of(code);

  /// Zero-padded official code: 022.
  String get number => code.toString().padLeft(3, '0');

  bool get isStamped => level != PassportLevel.none;

  /// Whether the county is in progress: started, not yet Gold.
  bool get isInProgress => isStamped && level != PassportLevel.gold;

  /// The small line under the name on the grid.
  String get subLine => switch (level) {
    PassportLevel.none => '',
    PassportLevel.passedThrough => 'Passed through',
    PassportLevel.explored => 'Explored',
    PassportLevel.bronze => 'Bronze',
    PassportLevel.silver => 'Silver',
    PassportLevel.gold => 'Complete',
  };
}
