import 'package:flutter/material.dart';

import '../../../core/design/app_type_scale.dart';
import '../../../core/widgets/county_badge_medallion.dart';
import '../../../counties/county_paths.dart';
import '../../../design/app_colors.dart';

/// "Passes through": the counties along the route, in order, as a row of
/// badges, with the ones the user has not claimed yet picked out. A
/// preview of the road, not a promise: badges come from where the Trip
/// actually goes.
class TripPlanCounties extends StatelessWidget {
  const TripPlanCounties({
    super.key,
    required this.countyCodes,
    required this.claimedCountyCodes,
  });

  final List<int> countyCodes;
  final Set<int> claimedCountyCodes;

  @override
  Widget build(BuildContext context) {
    final counties = [
      for (final code in countyCodes)
        if (CountyPaths.byCode[code] != null) CountyPaths.byCode[code]!,
    ];
    if (counties.isEmpty) return const SizedBox.shrink();
    final unclaimed = counties
        .where((c) => !claimedCountyCodes.contains(c.code))
        .length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            const Text('Passes through', style: AppTypeScale.sectionTitle),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                unclaimed == 0
                    ? 'all already yours'
                    : '$unclaimed of ${counties.length} not claimed yet',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypeScale.small,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 98,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: counties.length,
            separatorBuilder: (context, index) => const SizedBox(width: 12),
            itemBuilder: (context, index) => _CountyBadge(
              county: counties[index],
              earned: claimedCountyCodes.contains(counties[index].code),
            ),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Based on the planned road. A county counts once your Trip '
          'records you in it.',
          style: AppTypeScale.small,
        ),
      ],
    );
  }
}

/// The county's real badge: blue when claimed, grey when not. Unclaimed
/// ones carry a NEW tag so the ones worth the trip stand out.
class _CountyBadge extends StatelessWidget {
  const _CountyBadge({required this.county, required this.earned});

  final CountyPath county;
  final bool earned;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 72,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CountyBadgeMedallion(county: county, earned: earned, size: 56),
          const SizedBox(height: 4),
          Text(
            county.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypeScale.small.copyWith(color: AppColors.foreground),
          ),
          Text(
            earned ? 'CLAIMED' : 'NEW',
            style: AppTypeScale.sectionLabel.copyWith(
              color: earned ? AppColors.mutedForeground : AppColors.accent,
            ),
          ),
        ],
      ),
    );
  }
}
