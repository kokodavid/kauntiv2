import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../design/app_colors.dart';
import '../../../design/app_text_styles.dart';
import '../application/explore_providers.dart';
import '../domain/explore_board.dart';
import 'explore_header.dart';
import 'explore_mine_tab.dart';
import 'explore_resolving_state.dart';
import 'explore_styles.dart';

/// The Explore tab (v1 Discover & Wishlist): a title, one search bar and
/// MINE / UNCLAIMED / SAVED pills over the active tab's list.
///
/// Rendered inside the app's tab shell, which keeps it mounted once
/// visited, so the selected pill, search text and scroll position survive
/// switching tabs. MINE is ported; UNCLAIMED and SAVED follow.
class ExploreScreen extends ConsumerWidget {
  const ExploreScreen({super.key, this.onOpenCounty, this.onOpenPlace});

  final OpenExploreCounty? onOpenCounty;
  final OpenExplorePlace? onOpenPlace;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final board = ref.watch(exploreBoardProvider);
    return ColoredBox(
      color: AppColors.pageBackground,
      child: SafeArea(
        bottom: false,
        // A reload never shows the previous board (it could belong to a
        // previous account); the account-neutral skeleton shows instead.
        child: switch (board) {
          AsyncData(:final value) => _ExploreBoardView(
            board: value,
            onOpenCounty: onOpenCounty,
            onOpenPlace: onOpenPlace,
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
  });

  final ExploreBoard board;
  final OpenExploreCounty? onOpenCounty;
  final OpenExplorePlace? onOpenPlace;

  void _selectTab(BuildContext context, WidgetRef ref, ExploreTab tab) {
    if (tab != ExploreTab.mine) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('This list is coming next.')),
        );
      return;
    }
    ref.read(exploreTabSelectionProvider.notifier).select(tab);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tab = ref.watch(exploreTabSelectionProvider);
    final query = ref.watch(exploreSearchQueryProvider);
    final filtered = board.filtered(query);
    final noResults = query.trim().isNotEmpty && filtered.isEmpty;

    return CustomScrollView(
      key: const PageStorageKey('explore-scroll'),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 10),
          sliver: SliverList.list(
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
                counts: {ExploreTab.mine: filtered.mineCount},
                onSelected: (next) => _selectTab(context, ref, next),
              ),
            ],
          ),
        ),
        if (noResults)
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverToBoxAdapter(child: _NoSearchResults(query: query)),
          )
        else
          ExploreMineTab(
            board: filtered,
            onOpenCounty: onOpenCounty,
            onOpenPlace: onOpenPlace,
          ),
        // Keeps the last card clear of the floating tab bar.
        const SliverToBoxAdapter(child: SizedBox(height: 112)),
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
