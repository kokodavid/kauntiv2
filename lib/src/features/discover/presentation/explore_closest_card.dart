import 'package:flutter/material.dart';

import '../../../core/domain/app_stat_format.dart';
import '../../../core/widgets/app_feature_card.dart';
import '../domain/explore_board.dart';
import '../domain/explore_lists.dart';
import 'explore_place_row.dart';

/// UNCLAIMED's featured card, "CLOSEST ONE YOU DON'T HAVE", in the shared
/// feature-card design: a bare county photo with the label, then the
/// blurb and Area / Elevation / Distance / HQ. Tapping opens County Detail.
class ExploreClosestCard extends StatelessWidget {
  const ExploreClosestCard({super.key, required this.entry, this.onOpenCounty});

  final ExploreUnclaimedCounty entry;
  final OpenExploreCounty? onOpenCounty;

  @override
  Widget build(BuildContext context) {
    final open = onOpenCounty;
    final meters = entry.distanceMeters;
    return AppFeatureCard(
      county: entry.county,
      label: "CLOSEST ONE YOU DON'T HAVE",
      photoUrl: entry.highlightImageUrl,
      line: entry.blurb,
      stats: [
        ...exploreCountyStats(entry.facts),
        if (meters != null)
          (value: AppStatFormat.distance(meters), label: 'Distance'),
        if (entry.headquarters case final town?) (value: town, label: 'HQ'),
      ],
      onTap: () => open?.call(context, entry.county.code),
    );
  }
}
