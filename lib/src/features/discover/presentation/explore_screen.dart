import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/app_bottom_nav.dart';
import '../../../core/widgets/app_photo_parts.dart';
import '../../../design/app_colors.dart';
import '../../onboarding/application/startup_flow.dart';
import '../../profile/application/interests_providers.dart';
import '../../profile/domain/place_interest.dart';
import '../application/explore_headline_rotation_provider.dart';
import '../application/explore_providers.dart';
import '../domain/explore_board.dart';
import '../domain/explore_entries.dart';
import '../domain/explore_filters.dart';
import '../domain/explore_results.dart';
import 'explore_board_memo.dart';
import 'explore_counties_header.dart';
import 'explore_counties_landing.dart';
import 'explore_dock.dart';
import 'explore_dock_collapse.dart';
import 'explore_dock_types.dart';
import 'explore_filter_sheet.dart';
import 'explore_header.dart';
import 'explore_place_row.dart';
import 'explore_places_landing.dart';
import 'explore_resolving_state.dart';
import 'explore_results_view.dart';
import 'explore_saved_screen.dart';
import 'explore_search_body.dart';
import 'explore_states.dart';

/// The Explore tab (Field Guide v2): Places and Counties under one header
/// and a frosted dock. Kept mounted by the tab shell, so the mode, filters,
/// search text and scroll position survive switching tabs.
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
    ref.watch(exploreHeadlineRotationProvider); // settle it before the board
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
          AsyncError() => ExploreOfflineState(
            onRetry: () => ref.invalidate(exploreBoardProvider),
          ),
          _ => const ExploreResolvingState(),
        },
      ),
    );
  }
}

class _ExploreBoardView extends ConsumerStatefulWidget {
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
  ConsumerState<_ExploreBoardView> createState() => _ExploreBoardViewState();
}

class _ExploreBoardViewState extends ConsumerState<_ExploreBoardView>
    with ExploreDockCollapse<_ExploreBoardView> {
  ExploreViewMode _mode = ExploreViewMode.places;
  ExploreFilters _filters = const ExploreFilters.none();
  ExploreCountyScope _countyScope = ExploreCountyScope.all;
  bool _askInterests = false;
  final _memo = ExploreBoardMemo();

  void _setFilters(ExploreFilters next) => setState(() => _filters = next);

  void _chooseInterests() => setState(() {
    _filters = const ExploreFilters.none();
    _askInterests = true;
    _mode = ExploreViewMode.places;
  });

  Future<void> _openFilters({
    required List<ExploreEntry> entries,
    required bool hasLocation,
    required List<PlaceInterest> interests,
    required List<ExploreDockType> types,
  }) async {
    final next = await showExploreFilterSheet(
      context,
      initial: _filters,
      hasLocation: hasLocation,
      unclaimedCountyCount: widget.board.unclaimedCount,
      countFor: (filters) => entries.where(filters.matches).length,
      interestTypes: exploreInterestTypes(
        entries,
        interests,
        matcher: ref.read(interestMatcherProvider),
      ),
      types: types,
      totalCount: entries.length,
      onChooseInterests: interests.isEmpty ? _chooseInterests : null,
    );
    if (!mounted || next == null) return;
    _setFilters(next);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(exploreSearchQueryProvider, (_, _) => syncNav());
    final board = widget.board;
    final tab = ref.watch(exploreTabSelectionProvider);
    final mode = _mode;
    final query = ref.watch(exploreSearchQueryProvider);
    final matcher = ref.watch(interestMatcherProvider);
    final interests = ref.watch(myInterestsProvider).value;
    final picks = interests?.interests ?? const <PlaceInterest>[];
    final homeCounty = ref.watch(
      startupFlowProvider.select((flow) => flow.homeCounty?.name),
    );
    final filtered = _memo.filtered(board, query);
    final searching = query.trim().isNotEmpty;
    final entries = _memo.entries(board);
    final hasLocation = entries.any((entry) => entry.km != null);
    final locationUnavailable =
        entries.isNotEmpty &&
        !hasLocation &&
        board.unclaimed.every((county) => county.distanceMeters == null);
    final showResults = mode == ExploreViewMode.places && !_filters.isEmpty;

    if (tab == ExploreTab.saved) {
      return ExploreSavedScreen(
        board: filtered,
        onOpenPlace: widget.onOpenPlace,
        onBack: () => ref
            .read(exploreTabSelectionProvider.notifier)
            .select(ExploreTab.mine),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 10),
          child: ExploreFieldGuideHeader(
            mode: mode,
            savedCount: filtered.savedCount,
            onModeChanged: (next) => setState(() => _mode = next),
            onSavedTap: () => ref
                .read(exploreTabSelectionProvider.notifier)
                .select(ExploreTab.saved),
          ),
        ),
        Expanded(
          child: Stack(
            children: [
              NotificationListener<UserScrollNotification>(
                onNotification: (notification) {
                  handleScroll(notification);
                  return false;
                },
                child: CustomScrollView(
                  key: PageStorageKey('explore-scroll-${tab.name}'),
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  slivers: [
                    if (searching)
                      ExploreSearchBody(
                        board: filtered,
                        entries: entries,
                        query: query,
                        onOpenCounty: widget.onOpenCounty,
                        onOpenPlace: widget.onOpenPlace,
                        onBrowseType: (k) =>
                            _setFilters(ExploreFilters(typeKey: k)),
                      )
                    else
                      switch (mode) {
                        ExploreViewMode.places when showResults =>
                          ExploreResultsView(
                            filters: _filters,
                            results: buildExploreResults(
                              entries,
                              _filters,
                              hasLocation: hasLocation,
                            ),
                            similar: switch (_filters.typeKey) {
                              final key? => exploreSimilarTypes(
                                entries,
                                key,
                                matcher: matcher,
                              ),
                              null => const [],
                            },
                            onFiltersChanged: _setFilters,
                            onOpenPlace: widget.onOpenPlace,
                          ),
                        ExploreViewMode.places => ExplorePlacesLanding(
                          board: filtered,
                          onOpenPlace: widget.onOpenPlace,
                          noInterests: interests != null && picks.isEmpty,
                          locationUnavailable: locationUnavailable,
                          homeCountyName: homeCounty,
                          onSeeAll: _setFilters,
                          onSeeCounties: () => setState(() {
                            _mode = ExploreViewMode.counties;
                            _countyScope = ExploreCountyScope.mine;
                          }),
                          onOpenCounty: widget.onOpenCounty,
                          askInterests: _askInterests,
                          onAskHandled: () =>
                              setState(() => _askInterests = false),
                        ),
                        ExploreViewMode.counties => ExploreCountiesLanding(
                          board: filtered,
                          scope: _countyScope,
                          onScopeChanged: (next) =>
                              setState(() => _countyScope = next),
                          onOpenCounty: widget.onOpenCounty,
                        ),
                      },
                    SliverToBoxAdapter(
                      child: SizedBox(
                        height: AppBottomNav.clearance(context) + 76,
                      ),
                    ),
                  ],
                ),
              ),
              ExploreDockSlot(
                searching: searching,
                child: ExploreFieldGuideDock(
                  mode: mode,
                  filterCount: _filters.activeCount,
                  query: query,
                  onSearchChanged: (value) => ref
                      .read(exploreSearchQueryProvider.notifier)
                      .update(value),
                  onFilterTap: mode == ExploreViewMode.places
                      ? () => _openFilters(
                          entries: entries,
                          hasLocation: hasLocation,
                          interests: picks,
                          types: exploreDockTypes(
                            entries,
                            picks,
                            matcher: matcher,
                          ),
                        )
                      : () {},
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
