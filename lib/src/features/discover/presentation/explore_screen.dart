import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/app_photo_parts.dart';
import '../../../design/app_colors.dart';
import '../../../design/app_text_styles.dart';
import '../application/explore_providers.dart';
import '../domain/explore_board.dart';
import 'explore_header.dart';
import 'explore_mine_tab.dart';
import 'explore_place_row.dart';
import 'explore_resolving_state.dart';
import 'explore_saved_tab.dart';
import 'explore_styles.dart';
import 'explore_unclaimed_tab.dart';

/// The Explore tab (v1 Discover & Wishlist): a title, one search bar and
/// MINE / UNCLAIMED / SAVED pills over the active tab's list.
///
/// Rendered inside the app's tab shell, which keeps it mounted once
/// visited, so the selected pill, search text and scroll position survive
/// switching tabs.
class ExploreScreen extends ConsumerWidget {
  const ExploreScreen({
    super.key,
    this.onOpenCounty,
    this.onOpenPlace,
    this.onRoute,
  });

  final OpenExploreCounty? onOpenCounty;
  final OpenExplorePlace? onOpenPlace;

  /// Driving directions for the featured cards' Route buttons.
  final AppOpenDirections? onRoute;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final board = ref.watch(exploreBoardProvider);
    return ColoredBox(
      color: AppColors.pageBackground,
      child: SafeArea(
        bottom: false,
        // A refresh after a save keeps the current board on screen. The
        // first load shows an account-neutral skeleton; Explore unmounts
        // on sign-out, so a board never outlives its account.
        child: switch (board) {
          AsyncValue(:final value?, hasError: false) => _ExploreBoardView(
            board: value,
            onOpenCounty: onOpenCounty,
            onOpenPlace: onOpenPlace,
            onRoute: onRoute,
          ),
          AsyncError() => ExploreResolvingState(
            onRetry: () => ref.invalidate(exploreBoardProvider),
          ),
          _ => const ExploreResolvingState(),
        },
      ),
    );
  }
}

class _ExploreBoardView extends ConsumerWidget {
  const _ExploreBoardView({
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
  Widget build(BuildContext context, WidgetRef ref) {
    final tab = ref.watch(exploreTabSelectionProvider);
    final query = ref.watch(exploreSearchQueryProvider);
    final filtered = board.filtered(query);
    final noResults = query.trim().isNotEmpty && filtered.isEmpty;

    // The title, search and pills stay put; only the active list scrolls.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const ExploreTopBar(),
              const SizedBox(height: 12),
              ExploreSearchField(
                initialValue: query,
                onChanged: (value) =>
                    ref.read(exploreSearchQueryProvider.notifier).update(value),
              ),
              const SizedBox(height: 10),
              ExploreTabChips(
                selected: tab,
                counts: {
                  ExploreTab.mine: filtered.mineCount,
                  ExploreTab.unclaimed: filtered.unclaimedCount,
                  ExploreTab.saved: filtered.savedCount,
                },
                onSelected: (next) =>
                    ref.read(exploreTabSelectionProvider.notifier).select(next),
              ),
            ],
          ),
        ),
        Expanded(
          child: CustomScrollView(
            // One remembered scroll position per tab.
            key: PageStorageKey('explore-scroll-${tab.name}'),
            slivers: [
              if (noResults)
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverToBoxAdapter(
                    child: _NoSearchResults(query: query),
                  ),
                )
              else
                switch (tab) {
                  ExploreTab.mine => ExploreMineTab(
                    board: filtered,
                    onOpenCounty: onOpenCounty,
                    onOpenPlace: onOpenPlace,
                    onRoute: onRoute,
                  ),
                  ExploreTab.unclaimed => ExploreUnclaimedTab(
                    counties: filtered.unclaimed,
                    onOpenCounty: onOpenCounty,
                    onOpenPlace: onOpenPlace,
                    onRoute: onRoute,
                  ),
                  ExploreTab.saved => ExploreSavedTab(
                    board: filtered,
                    onOpenPlace: onOpenPlace,
                  ),
                },
              // Keeps the last card clear of the floating tab bar.
              const SliverToBoxAdapter(child: SizedBox(height: 112)),
            ],
          ),
        ),
      ],
    );
  }
}

class _NoSearchResults extends StatelessWidget {
  const _NoSearchResults({required this.query});

  final String query;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Nothing matches "$query"',
            style: AppTextStyles.chipLabel.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Try a county name or a place, across any tab.',
            style: ExploreStyles.emptyBody,
          ),
        ],
      ),
    );
  }
}
