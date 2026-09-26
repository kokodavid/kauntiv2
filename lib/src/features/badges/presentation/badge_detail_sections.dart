import 'package:flutter/material.dart';

import '../../../core/design/app_type_scale.dart';
import '../../../design/app_colors.dart';
import '../../map_home/domain/county_badge_state.dart';
import '../domain/badge_collection.dart';
import '../domain/county_badge_detail.dart';
import 'badge_places_section.dart';

const _muted = TextStyle(
  fontFamily: AppTypeScale.family,
  fontSize: 13,
  height: 20 / 13,
  color: AppColors.mutedForeground,
);

/// Earned date and what the next depth level needs.
class BadgeProgressSection extends StatelessWidget {
  const BadgeProgressSection({
    super.key,
    required this.badge,
    required this.detail,
  });

  final CountyBadge badge;
  final CountyBadgeDetail detail;

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', //
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  static String date(DateTime at) {
    final local = at.toLocal();
    return '${local.day} ${_months[local.month - 1]} ${local.year}';
  }

  @override
  Widget build(BuildContext context) {
    final earnedAt = detail.earnedAt;
    final step = DepthLadder.nextStep(
      badge.depth,
      visits: detail.exploredVisits,
      months: detail.exploredMonths,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (earnedAt != null)
          _Line(
            icon: Icons.verified_outlined,
            text: 'Earned ${date(earnedAt)}',
          ),
        _Line(
          icon: Icons.trending_up,
          text: step == null
              ? 'Local expert: the deepest level. It never expires.'
              : nextStepText(step),
        ),
      ],
    );
  }

  /// "2 more visits, in 2 different months, to become a Regular".
  static String nextStepText(DepthStep step) {
    final visits = step.visitsToGo;
    final visitWord = visits == 1 ? 'visit' : 'visits';
    final target = step.next.label.toLowerCase();
    if (visits == 0) return 'Your next visit makes you a $target.';
    final months = step.monthsNeeded;
    final inMonths = months <= 0
        ? ''
        : months == 1
        ? ', in a new month,'
        : ', in $months different months,';
    return '$visits more $visitWord$inMonths to become a $target.';
  }
}

/// "Your time in `<county>`": explored visits and the months they span
/// (what depth counts), the last visit, and Journeys here when there are
/// any.
class BadgeTimeSection extends StatelessWidget {
  const BadgeTimeSection({
    super.key,
    required this.countyName,
    required this.detail,
  });

  final String countyName;
  final CountyBadgeDetail detail;

  static String _plural(int n, String word) => n == 1 ? '1 $word' : '$n ${word}s';

  static String _distance(double meters) => meters < 1000
      ? '${meters.round()} m'
      : '${(meters / 1000).toStringAsFixed(meters < 10000 ? 1 : 0)} km';

  @override
  Widget build(BuildContext context) {
    final last = detail.lastVisitedAt;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Your time in $countyName', style: AppTypeScale.itemTitle),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _Stat(
                value: _plural(detail.exploredVisits, 'visit'),
                label: _plural(detail.exploredMonths, 'month'),
              ),
            ),
            if (last != null) ...[
              const SizedBox(width: 8),
              Expanded(
                child: _Stat(
                  value: BadgeProgressSection.date(last),
                  label: 'Last here',
                ),
              ),
            ],
            if (detail.journeys > 0) ...[
              const SizedBox(width: 8),
              Expanded(
                child: _Stat(
                  value: _plural(detail.journeys, 'Journey'),
                  label: _distance(detail.journeyMeters),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

/// For a county not yet earned: how to earn it and places to start with.
class BadgeHowToEarnSection extends StatelessWidget {
  const BadgeHowToEarnSection({
    super.key,
    required this.badge,
    required this.detail,
    this.onOpenPlace,
  });

  final CountyBadge badge;
  final CountyBadgeDetail detail;
  final ValueChanged<String>? onOpenPlace;

  @override
  Widget build(BuildContext context) {
    final name = badge.county.name;
    final how = switch (badge.state) {
      CountyBadgeState.pending =>
        'Your visit to $name is waiting to sync. The badge appears once '
            "it's confirmed.",
      CountyBadgeState.passedThrough =>
        "You've passed through $name. Spend about 2 hours here to earn "
            'the badge.',
      _ => 'Spend about 2 hours in $name to earn the badge.',
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Line(icon: Icons.flag_outlined, text: how),
        const SizedBox(height: 8),
        BadgePlacesSection(
          countyCode: badge.county.code,
          places: detail.suggestedPlaces,
          onOpenPlace: onOpenPlace,
        ),
      ],
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.accent),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: _muted.copyWith(color: AppColors.foreground),
            ),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.pageBackground,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypeScale.itemTitle,
          ),
          Text(label, style: _muted.copyWith(fontSize: 12)),
        ],
      ),
    );
  }
}
