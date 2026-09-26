import 'package:flutter/material.dart';

import '../../../core/design/app_type_scale.dart';
import '../../../design/app_colors.dart';
import '../../map_home/domain/county_badge_state.dart';
import '../domain/badge_collection.dart';
import '../domain/county_badge_detail.dart';

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

/// Saved places visited and how much of the county's places you've seen.
class BadgeCoverageSection extends StatelessWidget {
  const BadgeCoverageSection({super.key, required this.detail});

  final CountyBadgeDetail detail;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _Stat(
            value: '${detail.savedVisited} of ${detail.savedPlaces}',
            label: 'Saved places visited',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _Stat(
            value: '${detail.placesVisited} of ${detail.placesTotal}',
            label: 'County places ticked',
            progress: detail.placesTotal == 0
                ? null
                : detail.placesVisited / detail.placesTotal,
          ),
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
    final open = onOpenPlace;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Line(icon: Icons.flag_outlined, text: how),
        if (detail.suggestedPlaces.isNotEmpty) ...[
          const SizedBox(height: 8),
          const Text('Places to start with', style: AppTypeScale.itemTitle),
          for (final place in detail.suggestedPlaces)
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.place_outlined, color: AppColors.accent),
              title: Text(place.name, style: AppTypeScale.body),
              trailing: open == null
                  ? null
                  : const Icon(Icons.chevron_right, size: 18),
              onTap: open == null ? null : () => open(place.id),
            ),
        ],
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
  const _Stat({required this.value, required this.label, this.progress});

  final String value;
  final String label;
  final double? progress;

  @override
  Widget build(BuildContext context) {
    final progress = this.progress;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.pageBackground,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: AppTypeScale.cardTitle),
          Text(label, style: _muted.copyWith(fontSize: 12)),
          if (progress != null) ...[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: progress.clamp(0, 1).toDouble(),
                minHeight: 4,
                color: AppColors.accent,
                backgroundColor: AppColors.trackInactive,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
