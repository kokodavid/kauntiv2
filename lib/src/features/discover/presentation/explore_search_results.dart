import 'package:flutter/material.dart';

import '../../../core/design/app_type_scale.dart';
import '../../../counties/county_paths.dart';
import '../../../design/app_colors.dart';
import '../domain/explore_board.dart';
import '../domain/explore_entries.dart';
import 'explore_counties_landing.dart';
import 'explore_field_row.dart';
import 'explore_place_row.dart';
import 'explore_styles.dart';

/// Search results (design frame 2c): the query becomes the title, then
/// PLACES as result rows and COUNTIES as the same cards as the Counties view.
class ExploreSearchResults extends StatelessWidget {
  const ExploreSearchResults({
    super.key,
    required this.board,
    required this.query,
    this.onOpenCounty,
    this.onOpenPlace,
  });

  final ExploreBoard board;
  final String query;
  final OpenExploreCounty? onOpenCounty;
  final OpenExplorePlace? onOpenPlace;

  @override
  Widget build(BuildContext context) {
    final needle = query.trim().toLowerCase();
    final places = [
      for (final entry in exploreEntries(board))
        if (entry.place.matches(needle) ||
            entry.countyName.toLowerCase().contains(needle))
          entry,
    ];
    final counties = _matchingCounties(needle);
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverList.list(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 20),
            child: Text(
              '“${query.trim()}”',
              style: ExploreStyles.resultsSentence,
            ),
          ),
          if (places.isNotEmpty) ...[
            ExploreSectionHeader(label: 'PLACES', count: places.length),
            const SizedBox(height: 10),
            for (final entry in places) ...[
              ExploreFieldRow(entry: entry, onOpen: onOpenPlace),
              const SizedBox(height: 10),
            ],
          ],
          if (counties.isNotEmpty) ...[
            SizedBox(height: places.isEmpty ? 0 : 8),
            ExploreSectionHeader(label: 'COUNTIES', count: counties.length),
            const SizedBox(height: 10),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              crossAxisCount: 2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 171 / 214,
              children: [
                for (final county in counties)
                  ExploreCountyFieldCard(entry: county, onOpen: onOpenCounty),
              ],
            ),
          ],
        ],
      ),
    );
  }

  /// Counties whose name matches, with the same meta line the Counties
  /// view shows.
  List<ExploreCountyCardEntry> _matchingCounties(String needle) {
    final result = <ExploreCountyCardEntry>[];
    void add(
      CountyPath county, {
      required bool claimed,
      String? image,
      required String meta,
    }) {
      if (!county.name.toLowerCase().contains(needle)) return;
      result.add(
        ExploreCountyCardEntry(
          county: county,
          claimed: claimed,
          imageUrl: image,
          meta: meta,
        ),
      );
    }

    if (board.featuredUnlock case final unlock?) {
      add(
        unlock.county,
        claimed: true,
        image: unlock.highlightImageUrl,
        meta: 'Claimed',
      );
    }
    for (final entry in board.mine) {
      add(
        entry.county,
        claimed: true,
        image: entry.highlightImageUrl,
        meta: entry.isLocalExpert ? 'Local expert' : 'Claimed',
      );
    }
    for (final entry in board.unclaimed) {
      add(
        entry.county,
        claimed: false,
        image: entry.highlightImageUrl,
        meta: entry.distanceLabel?.replaceAll(' away', '') ?? 'Not claimed yet',
      );
    }
    return result;
  }
}

/// "PLACES ──────── 3": a small caps label, a rule and the count.
class ExploreSectionHeader extends StatelessWidget {
  const ExploreSectionHeader({
    super.key,
    required this.label,
    required this.count,
  });

  final String label;
  final int count;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Text(
        label,
        style: const TextStyle(
          fontFamily: AppTypeScale.family,
          fontSize: 10,
          fontWeight: FontWeight.w600,
          letterSpacing: .5,
          color: AppColors.mutedForeground,
        ),
      ),
      const SizedBox(width: 10),
      const Expanded(
        child: SizedBox(
          height: 1,
          child: ColoredBox(color: AppColors.exploreBorder),
        ),
      ),
      const SizedBox(width: 10),
      Text(
        '$count',
        style: const TextStyle(
          fontFamily: AppTypeScale.family,
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: AppColors.mutedForeground,
        ),
      ),
    ],
  );
}
