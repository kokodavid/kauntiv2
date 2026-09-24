import 'package:flutter/material.dart';

import '../../../core/widgets/app_photo_parts.dart';
import '../domain/explore_lists.dart';
import 'explore_closest_card.dart';
import 'explore_county_card.dart';
import 'explore_place_row.dart';
import 'explore_styles.dart';

/// Explore's UNCLAIMED list (v1 `DiscoverUnclaimedTab`): counties with no
/// explored visit, nearest first. The closest one is the featured card;
/// the rest use the same accordion as MINE, then a rarity note.
class ExploreUnclaimedTab extends StatelessWidget {
  const ExploreUnclaimedTab({
    super.key,
    required this.counties,
    this.onOpenCounty,
    this.onOpenPlace,
    this.onRoute,
  });

  /// Already nearest first (see [ExploreUnclaimedCounty.nearestFirst]).
  final List<ExploreUnclaimedCounty> counties;
  final OpenExploreCounty? onOpenCounty;
  final OpenExplorePlace? onOpenPlace;
  final AppOpenDirections? onRoute;

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverList.list(
        children: [
          if (counties.isNotEmpty) ...[
            ExploreClosestCard(
              entry: counties.first,
              onOpenCounty: onOpenCounty,
              onRoute: onRoute,
            ),
            const SizedBox(height: 16),
            for (var i = 1; i < counties.length; i++) ...[
              ExploreCountyCard(
                key: ValueKey(counties[i].county.code),
                county: counties[i].county,
                statusLabel: counties[i].rarityLabel,
                placeCount: counties[i].placeCount,
                child: _CountyBody(
                  entry: counties[i],
                  onOpenCounty: onOpenCounty,
                  onOpenPlace: onOpenPlace,
                ),
              ),
              if (i != counties.length - 1) const SizedBox(height: 10),
            ],
            const SizedBox(height: 16),
            const _RarityInsightCard(),
          ],
        ],
      ),
    );
  }
}

class _CountyBody extends StatelessWidget {
  const _CountyBody({required this.entry, this.onOpenCounty, this.onOpenPlace});

  final ExploreUnclaimedCounty entry;
  final OpenExploreCounty? onOpenCounty;
  final OpenExplorePlace? onOpenPlace;

  @override
  Widget build(BuildContext context) {
    final places = entry.previewPlaces;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 12, bottom: 4),
          child: Text(entry.blurb, style: ExploreStyles.emptyBody),
        ),
        // The blurb already says when there are no places.
        if (places.isNotEmpty)
          ExplorePlaceList(
            places: places,
            countyCode: entry.county.code,
            onOpenPlace: onOpenPlace,
          ),
        ExploreCountyPageLink(
          countyCode: entry.county.code,
          onOpenCounty: onOpenCounty,
        ),
      ],
    );
  }
}

class _RarityInsightCard extends StatelessWidget {
  const _RarityInsightCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: ExploreStyles.cardDecoration,
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Short lists mean few people go.',
            style: ExploreStyles.insightTitle,
          ),
          SizedBox(height: 4),
          Text(
            'Rare counties are worth more on the leaderboard — Mandera '
            'scores 9× Nairobi.',
            style: ExploreStyles.emptyBody,
          ),
        ],
      ),
    );
  }
}
