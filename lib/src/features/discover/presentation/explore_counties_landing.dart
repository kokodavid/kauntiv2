import 'package:flutter/material.dart';

import '../../../core/widgets/app_network_image.dart';
import '../../../core/widgets/county_badge_medallion.dart';
import '../../../counties/county_paths.dart';
import '../../../design/app_colors.dart';
import '../domain/explore_board.dart';
import 'explore_counties_header.dart';
import 'explore_place_row.dart';
import 'explore_states.dart';
import 'explore_styles.dart';

/// Field Guide's Counties view: compact photo cards in a two-column grid.
class ExploreCountiesLanding extends StatelessWidget {
  const ExploreCountiesLanding({
    super.key,
    required this.board,
    required this.scope,
    required this.onScopeChanged,
    this.onOpenCounty,
  });

  final ExploreBoard board;
  final ExploreCountyScope scope;
  final ValueChanged<ExploreCountyScope> onScopeChanged;
  final OpenExploreCounty? onOpenCounty;

  @override
  Widget build(BuildContext context) {
    final counties = _counties();
    final claimed = board.mineCount;
    final total = claimed + board.unclaimedCount;
    return SliverMainAxisGroup(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverToBoxAdapter(
            child: ExploreCountiesHeader(
              claimed: claimed,
              total: total,
              scope: scope,
              onScopeChanged: onScopeChanged,
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 16)),
        if (counties.isEmpty)
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverToBoxAdapter(
              child: ExploreStateNotice(
                title: scope == ExploreCountyScope.open
                    ? 'All $total counties explored'
                    : 'No counties here yet',
                message: scope == ExploreCountyScope.open
                    ? 'You have unlocked every county in your collection.'
                    : 'Counties you explore will appear here.',
                icon: scope == ExploreCountyScope.open
                    ? Icons.verified_rounded
                    : Icons.map_outlined,
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverGrid(
              delegate: SliverChildBuilderDelegate(
                (context, index) => ExploreCountyFieldCard(
                  entry: counties[index],
                  onOpen: onOpenCounty,
                ),
                childCount: counties.length,
              ),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 4 / 3,
              ),
            ),
          ),
      ],
    );
  }

  /// Claimed first, then open counties nearest first (the board already
  /// orders both).
  List<ExploreCountyCardEntry> _counties() {
    final claimed = <ExploreCountyCardEntry>[
      if (board.featuredUnlock case final unlock?)
        ExploreCountyCardEntry(
          county: unlock.county,
          claimed: true,
          imageUrl: unlock.highlightImageUrl,
          meta: 'Claimed',
        ),
      for (final entry in board.mine)
        ExploreCountyCardEntry(
          county: entry.county,
          claimed: true,
          imageUrl: entry.highlightImageUrl,
          meta: entry.isLocalExpert ? 'Local expert' : 'Claimed',
        ),
    ];
    final open = <ExploreCountyCardEntry>[
      for (final entry in board.unclaimed)
        ExploreCountyCardEntry(
          county: entry.county,
          claimed: false,
          imageUrl: entry.highlightImageUrl,
          meta:
              entry.distanceLabel?.replaceAll(' away', '') ?? 'Not claimed yet',
        ),
    ];
    return switch (scope) {
      ExploreCountyScope.all => [...claimed, ...open],
      ExploreCountyScope.mine => claimed,
      ExploreCountyScope.open => open,
    };
  }
}

/// A county card's content: the highlight photo, claim state and meta line.
class ExploreCountyCardEntry {
  const ExploreCountyCardEntry({
    required this.county,
    required this.claimed,
    required this.imageUrl,
    required this.meta,
  });

  final CountyPath county;
  final bool claimed;
  final String? imageUrl;
  final String meta;
}

class ExploreCountyFieldCard extends StatelessWidget {
  const ExploreCountyFieldCard({super.key, required this.entry, this.onOpen});

  final ExploreCountyCardEntry entry;
  final OpenExploreCounty? onOpen;

  @override
  Widget build(BuildContext context) {
    final imageUrl = entry.imageUrl;
    return Material(
      color: imageUrl == null ? AppColors.exploreSurface : Colors.transparent,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.exploreBorder),
      ),
      child: InkWell(
        onTap: onOpen == null
            ? null
            : () => onOpen!(context, entry.county.code),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (imageUrl case final url?)
              Image(
                image: appNetworkImage(url, cacheWidth: 512),
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    _SilhouetteBody(county: entry.county),
              )
            else
              _SilhouetteBody(county: entry.county),
            if (imageUrl != null) const _CountyPhotoShade(),
            Positioned(
              top: 10,
              left: 10,
              child: CountyBadgeMedallion(
                county: entry.county,
                earned: entry.claimed,
                size: 32,
              ),
            ),
            Positioned(
              left: 12,
              right: 12,
              bottom: 12,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.county.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: ExploreStyles.countyFieldTitle(
                      onImage: imageUrl != null,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    entry.meta,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: ExploreStyles.countyFieldMeta(
                      onImage: imageUrl != null,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CountyPhotoShade extends StatelessWidget {
  const _CountyPhotoShade();

  @override
  Widget build(BuildContext context) => const DecoratedBox(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0x18000000), Color(0xD9000000)],
        stops: [0.45, 1],
      ),
    ),
  );
}

class _SilhouetteBody extends StatelessWidget {
  const _SilhouetteBody({required this.county});

  final CountyPath county;

  @override
  Widget build(BuildContext context) => Center(
    child: CountyBadgeMedallion(county: county, earned: false, size: 72),
  );
}
