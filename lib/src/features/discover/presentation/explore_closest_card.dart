import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/app_feature_card.dart';
import '../../../core/widgets/app_photo_parts.dart';
import '../application/explore_providers.dart';
import '../domain/explore_board.dart';
import '../domain/explore_lists.dart';
import 'explore_place_row.dart';

/// UNCLAIMED's featured card, "CLOSEST ONE YOU DON'T HAVE", in the shared
/// feature-card design: county photo, distance, blurb and stats, with
/// Save and Route on the photo. Tapping opens County Detail.
class ExploreClosestCard extends ConsumerWidget {
  const ExploreClosestCard({
    super.key,
    required this.entry,
    this.onOpenCounty,
    this.onRoute,
  });

  final ExploreUnclaimedCounty entry;
  final OpenExploreCounty? onOpenCounty;
  final AppOpenDirections? onRoute;

  Future<void> _toggleSaved(
    BuildContext context,
    WidgetRef ref,
    bool saved,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref
          .read(exploreSavedCountiesProvider.notifier)
          .setSaved(countyCode: entry.county.code, saved: !saved);
    } on Object {
      messenger.showSnackBar(
        const SnackBar(content: Text("Couldn't update your saved counties.")),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final saved =
        ref.watch(
          exploreSavedCountiesProvider.select((m) => m[entry.county.code]),
        ) ??
        entry.isSavedAlone;
    final route = onRoute;
    final open = onOpenCounty;

    return AppFeatureCard(
      county: entry.county,
      label: "CLOSEST ONE YOU DON'T HAVE",
      photoTitle: entry.county.name,
      photoCaption: entry.distanceLabel ??
          (entry.headquarters == null
              ? entry.rarityLabel
              : 'HQ · ${entry.headquarters}'),
      photoUrl: entry.highlightImageUrl,
      line: entry.blurb,
      stats: exploreCountyStats(entry.facts),
      actions: [
        AppPhotoButton(
          label: saved ? 'Saved' : 'Save',
          icon: saved ? Icons.bookmark : Icons.bookmark_border,
          onPressed: () => _toggleSaved(context, ref, saved),
        ),
        if (route != null)
          AppPhotoButton(
            onPressed: () => openRoute(
              context,
              '${entry.county.name} County, Kenya',
              route,
            ),
          ),
      ],
      onTap: () => open?.call(context, entry.county.code),
    );
  }
}
