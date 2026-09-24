import 'package:flutter/material.dart';

import '../../../design/app_colors.dart';
import '../domain/explore_board.dart';
import 'explore_county_card.dart';
import 'explore_place_row.dart';
import 'explore_styles.dart';
import 'explore_wishlist_row.dart';

/// Explore's SAVED list, the Wishlist (v1 `DiscoverSavedTab`): saved
/// places grouped by county, most recently saved first, each with a
/// hand-ticked checkbox. Ticks are a personal checklist: the app only
/// confirms counties, never individual places.
class ExploreSavedTab extends StatelessWidget {
  const ExploreSavedTab({super.key, required this.board, this.onOpenPlace});

  final ExploreBoard board;
  final OpenExplorePlace? onOpenPlace;

  @override
  Widget build(BuildContext context) {
    final groups = board.saved;
    if (groups.isEmpty) {
      return const SliverPadding(
        padding: EdgeInsets.symmetric(horizontal: 16),
        sliver: SliverToBoxAdapter(child: _EmptySavedCard()),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverList.list(
        children: [
          Text(
            '${_count(board.savedCount, 'place', 'places')} saved across '
            '${_count(groups.length, 'county', 'counties')}',
            style: ExploreStyles.savedMeta,
          ),
          const SizedBox(height: 12),
          for (var i = 0; i < groups.length; i++) ...[
            ExploreCountyCard(
              key: ValueKey(groups[i].county.code),
              county: groups[i].county,
              statusLabel: groups[i].statusLabel,
              placeCount: groups[i].places.length,
              initiallyExpanded: i == 0,
              child: groups[i].places.isEmpty
                  ? const _SavedCountyOnly()
                  : Column(
                      children: [
                        for (var j = 0; j < groups[i].places.length; j++) ...[
                          if (j != 0)
                            const Divider(
                              height: 1,
                              color: AppColors.exploreBorder,
                            ),
                          ExploreWishlistRow(
                            place: groups[i].places[j],
                            onOpen: onOpenPlace,
                          ),
                        ],
                      ],
                    ),
            ),
            const SizedBox(height: 12),
          ],
          const SizedBox(height: 4),
          const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.info_outline,
                size: 13,
                color: AppColors.mutedForeground,
              ),
              SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Places are ticked by hand. The app only knows which '
                  'county you were in, never where you stood.',
                  style: ExploreStyles.savedMeta,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SavedCountyOnly extends StatelessWidget {
  const _SavedCountyOnly();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'You saved the county from Discover.',
            style: ExploreStyles.emptyBody,
          ),
          SizedBox(height: 6),
          Text('Pick some places →', style: ExploreStyles.link),
        ],
      ),
    );
  }
}

class _EmptySavedCard extends StatelessWidget {
  const _EmptySavedCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: ExploreStyles.cardDecoration,
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Nothing saved yet', style: ExploreStyles.insightTitle),
          SizedBox(height: 4),
          Text(
            'Bookmark a county or a place from Discover and it shows up '
            'here.',
            style: ExploreStyles.emptyBody,
          ),
        ],
      ),
    );
  }
}

String _count(int n, String one, String many) => '$n ${n == 1 ? one : many}';
