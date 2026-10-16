import 'package:flutter/material.dart';

import '../../../counties/county_paths.dart';
import '../domain/explore_board.dart';
import '../domain/explore_entries.dart';
import '../domain/explore_headline.dart';
import 'explore_chapter_header.dart';
import 'explore_counties_landing.dart';
import 'explore_place_row.dart';

/// Claimed counties, the one visited longest ago first. Counties with no
/// known date come last.
List<({String name, int code, DateTime? at, String? image})>
exploreGoBackCounties(ExploreBoard board) {
  final all = [
    if (board.featuredUnlock case final unlock?)
      (
        name: unlock.county.name,
        code: unlock.county.code,
        at: unlock.lastVisitedAt,
        image: unlock.highlightImageUrl,
      ),
    for (final entry in board.mine)
      (
        name: entry.county.name,
        code: entry.county.code,
        at: entry.lastVisitedAt,
        image: entry.highlightImageUrl,
      ),
  ];
  all.sort((a, b) {
    if (a.at == null && b.at == null) return 0;
    if (a.at == null) return 1;
    if (b.at == null) return -1;
    return a.at!.compareTo(b.at!);
  });
  return all;
}

/// Places in the counties visited longest ago, for the "Go back" chapter.
List<ExploreEntry> exploreGoBackPlaces(
  ExploreBoard board,
  List<ExploreEntry> entries,
) {
  final order = {
    for (final (i, county) in exploreGoBackCounties(board).indexed)
      county.code: i,
  };
  final claimed = [
    for (final entry in entries)
      if (entry.claimed) entry,
  ];
  claimed.sort(
    (a, b) =>
        (order[a.countyCode] ?? 999).compareTo(order[b.countyCode] ?? 999),
  );
  return claimed;
}

/// "Counties you haven't visited in a while": two county cards with the
/// month of the last visit.
class ExploreGoBackCounties extends StatelessWidget {
  const ExploreGoBackCounties({
    super.key,
    required this.board,
    this.onSeeAll,
    this.onOpenCounty,
  });

  final ExploreBoard board;
  final VoidCallback? onSeeAll;
  final OpenExploreCounty? onOpenCounty;

  @override
  Widget build(BuildContext context) {
    final counties = [
      for (final c in exploreGoBackCounties(board))
        if (c.at != null) c,
    ].take(2).toList();
    if (counties.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ExploreChapterHeader(
            kicker: 'Go back',
            title: "Counties you haven't visited in a while",
            action: onSeeAll == null ? null : 'See all',
            onAction: onSeeAll,
          ),
          const SizedBox(height: 12),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            crossAxisCount: 2,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 171 / 214,
            children: [
              for (final c in counties)
                ExploreCountyFieldCard(
                  onOpen: onOpenCounty,
                  entry: ExploreCountyCardEntry(
                    county: _path(board, c.code),
                    claimed: true,
                    imageUrl: c.image,
                    meta: 'Last here ${exploreMonthYear(c.at!)}',
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  static CountyPath _path(ExploreBoard board, int code) {
    if (board.featuredUnlock case final unlock?
        when unlock.county.code == code) {
      return unlock.county;
    }
    return board.mine.firstWhere((m) => m.county.code == code).county;
  }
}
