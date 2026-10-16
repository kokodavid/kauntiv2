import 'package:flutter/material.dart';

import '../domain/explore_board.dart';
import '../domain/explore_entries.dart';
import 'explore_place_row.dart';
import 'explore_search_empty.dart';
import 'explore_search_results.dart';

/// The sliver Explore shows while the traveller is searching: the matches,
/// or the "nothing matches" help when there are none.
class ExploreSearchBody extends StatelessWidget {
  const ExploreSearchBody({
    super.key,
    required this.board,
    required this.entries,
    required this.query,
    required this.onOpenCounty,
    required this.onOpenPlace,
    required this.onBrowseType,
  });

  /// The board already narrowed to [query].
  final ExploreBoard board;
  final List<ExploreEntry> entries;
  final String query;
  final OpenExploreCounty? onOpenCounty;
  final OpenExplorePlace? onOpenPlace;
  final ValueChanged<String> onBrowseType;

  @override
  Widget build(BuildContext context) {
    if (board.isEmpty) {
      return SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        sliver: SliverToBoxAdapter(
          child: ExploreSearchEmpty(
            query: query,
            entries: entries,
            onOpenCounty: onOpenCounty,
            onBrowseType: onBrowseType,
          ),
        ),
      );
    }
    return ExploreSearchResults(
      board: board,
      query: query,
      onOpenCounty: onOpenCounty,
      onOpenPlace: onOpenPlace,
    );
  }
}
