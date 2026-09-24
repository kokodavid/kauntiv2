import 'package:flutter/material.dart';

import '../../../design/app_colors.dart';
import '../domain/explore_board.dart';
import 'explore_county_card.dart';
import 'explore_place_row.dart';
import 'explore_styles.dart';

typedef OpenExploreCounty = void Function(BuildContext context, int countyCode);
typedef OpenExplorePlace = void Function(BuildContext context, String placeId);

/// Explore's MINE feed (v1 `DiscoverMineTab`, Figma 407:4113): the latest
/// unlock first, then the traveller's other explored counties, the first
/// one expanded.
class ExploreMineTab extends StatelessWidget {
  const ExploreMineTab({
    super.key,
    required this.board,
    this.onOpenCounty,
    this.onOpenPlace,
  });

  final ExploreBoard board;
  final OpenExploreCounty? onOpenCounty;
  final OpenExplorePlace? onOpenPlace;

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
              onOpenPlace: onOpenPlace,
            ),
            const SizedBox(height: 20),
          ],
          const Text('MINE', style: ExploreStyles.sectionKicker),
          const SizedBox(height: 4),
          const Text('Nearby and unclaimed', style: ExploreStyles.sectionTitle),
          const SizedBox(height: 12),
          if (mine.isEmpty)
            const _EmptyMineCard()
          else
            for (var i = 0; i < mine.length; i++) ...[
              ExploreCountyCard(
                key: ValueKey(mine[i].county.code),
                county: mine[i].county,
                statusLabel: mine[i].statusLabel,
                placeCount: mine[i].placeCount,
                initiallyExpanded: i == 0,
                child: _PlaceList(
                  places: mine[i].previewPlaces,
                  countyCode: mine[i].county.code,
                  onOpenPlace: onOpenPlace,
                ),
              ),
              if (i != mine.length - 1) const SizedBox(height: 10),
            ],
        ],
      ),
    );
  }
}

class _FeaturedUnlockCard extends StatelessWidget {
  const _FeaturedUnlockCard({
    required this.unlock,
    this.onOpenCounty,
    this.onOpenPlace,
  });

  final ExploreFeaturedUnlock unlock;
  final OpenExploreCounty? onOpenCounty;
  final OpenExplorePlace? onOpenPlace;

  @override
  Widget build(BuildContext context) {
    final openCounty = onOpenCounty;
    return Container(
      decoration: ExploreStyles.cardDecoration,
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Row(
                children: [
                  ExploreCountyShapeTile(county: unlock.county),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ExploreCountyHeading(
                      name: unlock.county.name,
                      statusLabel: unlock.rarityLabel,
                      pill: const _UnlockPill(),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.exploreBorder),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _PlaceList(
                places: unlock.previewPlaces.take(2).toList(),
                countyCode: unlock.county.code,
                onOpenPlace: onOpenPlace,
              ),
            ),
            InkWell(
              onTap: openCounty == null
                  ? null
                  : () => openCounty(context, unlock.county.code),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
                child: Text(
                  'ALL ${unlock.totalPlaceCount} PLACES IN '
                  '${unlock.county.name.toUpperCase()}  →',
                  style: ExploreStyles.link,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlaceList extends StatelessWidget {
  const _PlaceList({
    required this.places,
    required this.countyCode,
    this.onOpenPlace,
  });

  final List<ExplorePlace> places;
  final int countyCode;
  final OpenExplorePlace? onOpenPlace;

  @override
  Widget build(BuildContext context) {
    if (places.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Text(
          'No places on file yet for this county.',
          style: ExploreStyles.emptyBody,
        ),
      );
    }
    return Column(
      children: [
        for (var i = 0; i < places.length; i++) ...[
          ExplorePlaceRow(
            place: places[i],
            countyCode: countyCode,
            onOpen: onOpenPlace,
          ),
          if (i != places.length - 1)
            const Divider(height: 1, color: AppColors.exploreBorder),
        ],
      ],
    );
  }
}

class _UnlockPill extends StatelessWidget {
  const _UnlockPill();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.exploreUnlockFill,
        border: Border.all(color: AppColors.exploreUnlockBorder),
        borderRadius: BorderRadius.circular(6),
      ),
      child: const Text('JUST UNLOCKED', style: ExploreStyles.unlockPill),
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
