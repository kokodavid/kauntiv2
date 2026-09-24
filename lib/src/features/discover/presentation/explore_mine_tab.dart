import 'package:flutter/material.dart';

import '../../../core/widgets/app_feature_card.dart';
import '../../../core/widgets/app_photo_parts.dart';
import '../domain/explore_board.dart';
import 'explore_county_card.dart';
import 'explore_place_row.dart';
import 'explore_styles.dart';

/// Explore's MINE feed (v1 `DiscoverMineTab`, Figma 407:4113): the latest
/// unlock first, then the traveller's other explored counties, the first
/// one expanded.
class ExploreMineTab extends StatelessWidget {
  const ExploreMineTab({
    super.key,
    required this.board,
    this.onOpenCounty,
    this.onOpenPlace,
    this.onRoute,
  });

  final ExploreBoard board;
  final OpenExploreCounty? onOpenCounty;
  final OpenExplorePlace? onOpenPlace;
  final AppOpenDirections? onRoute;

  @override
  Widget build(BuildContext context) {
    final mine = board.mine;
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverList.list(
        children: [
          if (board.featuredUnlock case final unlock?) ...[
            _FeaturedUnlockCard(
              unlock: unlock,
              onOpenCounty: onOpenCounty,
              onRoute: onRoute,
            ),
            const SizedBox(height: 10),
          ],
          if (mine.isEmpty && board.featuredUnlock == null)
            const _EmptyMineCard()
          else
            for (var i = 0; i < mine.length; i++) ...[
              ExploreCountyCard(
                key: ValueKey(mine[i].county.code),
                county: mine[i].county,
                statusLabel: mine[i].statusLabel,
                placeCount: mine[i].placeCount,
                initiallyExpanded: i == 0,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ExplorePlaceList(
                      places: mine[i].previewPlaces,
                      countyCode: mine[i].county.code,
                      onOpenPlace: onOpenPlace,
                    ),
                    ExploreCountyPageLink(
                      countyCode: mine[i].county.code,
                      onOpenCounty: onOpenCounty,
                    ),
                  ],
                ),
              ),
              if (i != mine.length - 1) const SizedBox(height: 10),
            ],
        ],
      ),
    );
  }
}

/// MINE's "JUST UNLOCKED" card in the shared feature-card design: the
/// newest explored county's photo, rarity, blurb and stats, with Route.
/// Tapping opens County Detail.
class _FeaturedUnlockCard extends StatelessWidget {
  const _FeaturedUnlockCard({
    required this.unlock,
    this.onOpenCounty,
    this.onRoute,
  });

  final ExploreFeaturedUnlock unlock;
  final OpenExploreCounty? onOpenCounty;
  final AppOpenDirections? onRoute;

  @override
  Widget build(BuildContext context) {
    final route = onRoute;
    final open = onOpenCounty;
    return AppFeatureCard(
      county: unlock.county,
      label: 'JUST UNLOCKED',
      photoTitle: unlock.county.name,
      photoCaption: unlock.caption,
      photoUrl: unlock.highlightImageUrl,
      line: unlock.blurb,
      stats: exploreCountyStats(unlock.facts),
      actions: [
        if (route != null)
          AppPhotoButton(
            onPressed: () => openRoute(
              context,
              '${unlock.county.name} County, Kenya',
              route,
            ),
          ),
      ],
      onTap: () => open?.call(context, unlock.county.code),
    );
  }
}

class _EmptyMineCard extends StatelessWidget {
  const _EmptyMineCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: ExploreStyles.cardDecoration,
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Nothing here yet', style: ExploreStyles.countyTitle),
          SizedBox(height: 4),
          Text(
            'Counties you explore or pass through will appear here.',
            style: ExploreStyles.emptyBody,
          ),
        ],
      ),
    );
  }
}
