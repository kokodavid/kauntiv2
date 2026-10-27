import 'county_badge_detail.dart';
import 'passport_level.dart';
import 'passport_rules.dart';

/// A place the user was verified at. Nothing creates these yet; saved or
/// ticked places are never evidence.
class VerifiedPlace {
  const VerifiedPlace({
    required this.id,
    required this.name,
    required this.category,
    required this.visitedAt,
    this.thumbnailUrl,
  });

  final String id;
  final String name;
  final String category;
  final DateTime visitedAt;
  final String? thumbnailUrl;
}

/// What a county has verified so far. [none] until place verification ships;
/// the Passport reads evidence only through this class, so that is the one
/// place the verified data plugs in.
class PassportEvidence {
  const PassportEvidence({this.places = const [], this.visitDays = 0});

  static const none = PassportEvidence();

  final List<VerifiedPlace> places;
  final int visitDays;

  int get categories => places.map((p) => p.category).toSet().length;
}

/// One line of a milestone card: "Verified places 2 of 3".
class PassportMilestoneRow {
  const PassportMilestoneRow({
    required this.label,
    required this.value,
    required this.target,
  });

  final String label;
  final int value;
  final int target;

  bool get isDone => value >= target;
  double get ratio => target == 0 ? 1 : (value / target).clamp(0.0, 1.0);
}

/// How a stamp on the row looks. [locked] is the next stamp when the county
/// can't offer it yet.
enum PassportStampState { earned, next, locked, future }

/// A county's way to its next stamp.
class PassportProgress {
  const PassportProgress({
    required this.level,
    required this.next,
    required this.rows,
    required this.fraction,
    required this.isLater,
    required this.lock,
    required this.longestVisit,
    required this.exploredStay,
  });

  /// Where the county stands, the stamp it works towards (null at Gold),
  /// and the milestone lines for a metal stamp.
  final PassportLevel level;
  final PassportLevel? next;
  final List<PassportMilestoneRow> rows;

  /// 0..1 towards [next]; null when there is no figure (not started).
  final double? fraction;

  /// True when [next] is a metal stamp that can't be earned yet because
  /// places aren't verified: shown as a dashed future stamp.
  final bool isLater;

  /// Set when [next] is a metal stamp this county can't offer yet because
  /// it has too few reviewed places or categories.
  final PassportLock? lock;

  final Duration longestVisit;
  final Duration exploredStay;

  /// Whole percent for the progress ring; null with no figure.
  int? get percent => fraction == null ? null : (fraction! * 100).round();

  PassportStampState stampState(PassportLevel stamp) {
    if (stamp.isReachedAt(level) && level != PassportLevel.none) {
      return PassportStampState.earned;
    }
    if (stamp == next && !isLater) {
      return lock == null ? PassportStampState.next : PassportStampState.locked;
    }
    return PassportStampState.future;
  }

  /// [detail] gives the longest recent visit; [totalPlaces] caps a county
  /// with few reviewed places.
  factory PassportProgress.of({
    required PassportLevel level,
    required CountyBadgeDetail detail,
    required PassportRules rules,
    PassportEvidence evidence = PassportEvidence.none,
  }) {
    final longest = detail.lastPassStay ?? Duration.zero;
    final next = level.next;
    if (next == null) {
      return PassportProgress._(
        level,
        null,
        const [],
        1,
        false,
        null,
        longest,
        rules,
      );
    }
    if (!next.isMetal) {
      final fraction = switch (level) {
        PassportLevel.none => null,
        _ =>
          rules.exploredStay.inSeconds == 0
              ? 1.0
              : (longest.inSeconds / rules.exploredStay.inSeconds).clamp(
                  0.0,
                  1.0,
                ),
      };
      return PassportProgress._(
        level,
        next,
        const [],
        fraction,
        false,
        null,
        longest,
        rules,
      );
    }
    final milestone = rules.milestoneFor(next);
    final rows = <PassportMilestoneRow>[];
    if (milestone != null) {
      rows
        ..add(
          PassportMilestoneRow(
            label: 'Verified places',
            value: evidence.places.length,
            target: milestone.places,
          ),
        )
        ..add(
          PassportMilestoneRow(
            label: 'Categories',
            value: evidence.categories,
            target: milestone.categories,
          ),
        )
        ..add(
          PassportMilestoneRow(
            label: milestone.visitDays == 1 ? 'Return visit day' : 'Visit days',
            value: evidence.visitDays,
            target: milestone.visitDays,
          ),
        );
    }
    final fraction = rows.isEmpty
        ? 0.0
        : rows.map((r) => r.ratio).reduce((a, b) => a + b) / rows.length;
    return PassportProgress._(
      level,
      next,
      rows,
      fraction,
      !rules.placeVerificationLive,
      rules.lockFor(
        next,
        placesTotal: detail.placesTotal,
        categoriesTotal: detail.categoriesTotal,
      ),
      longest,
      rules,
    );
  }

  PassportProgress._(
    this.level,
    this.next,
    this.rows,
    this.fraction,
    this.isLater,
    this.lock,
    this.longestVisit,
    PassportRules rules,
  ) : exploredStay = rules.exploredStay;
}
