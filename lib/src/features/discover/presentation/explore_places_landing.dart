import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../profile/application/interests_providers.dart';
import '../../profile/domain/place_interest.dart';
import '../application/explore_headline_rotation_provider.dart';
import '../application/explore_nearby_providers.dart';
import '../domain/explore_board.dart';
import '../domain/explore_entries.dart';
import '../domain/explore_filters.dart';
import 'explore_chapter.dart';
import 'explore_chapter_header.dart';
import 'explore_go_back.dart';
import 'explore_headline_view.dart';
import 'explore_interest_prompt.dart';
import 'explore_landing_data.dart';
import 'explore_place_row.dart';

/// The editorial Places landing page in Explore Field Guide v2.
///
/// The board is already loaded as one snapshot, so the lead and chapter
/// counts are derived from the same data and cannot briefly disagree.
class ExplorePlacesLanding extends ConsumerStatefulWidget {
  const ExplorePlacesLanding({
    super.key,
    required this.board,
    this.onOpenPlace,
    this.noInterests = false,
    this.locationUnavailable = false,
    this.homeCountyName,
    this.onSeeAll,
    this.onSeeCounties,
    this.onOpenCounty,
    this.askInterests = false,
    this.onAskHandled,
  });

  final ExploreBoard board;
  final OpenExplorePlace? onOpenPlace;

  /// The traveller has not picked interests: show the question (frame 4e)
  /// and only the "Near you" chapter.
  final bool noInterests;
  final bool locationUnavailable;
  final String? homeCountyName;

  /// A chapter's "See all": opens the results view with these filters.
  final void Function(ExploreFilters filters)? onSeeAll;

  /// "See all" on the Go back counties chapter: opens the Counties view.
  final VoidCallback? onSeeCounties;
  final OpenExploreCounty? onOpenCounty;

  /// Opens the interest picker (asked for from the filter sheet), then
  /// reports back through [onAskHandled].
  final bool askInterests;
  final VoidCallback? onAskHandled;

  @override
  ConsumerState<ExplorePlacesLanding> createState() =>
      _ExplorePlacesLandingState();
}

class _ExplorePlacesLandingState extends ConsumerState<ExplorePlacesLanding> {
  // Once the question has been shown it stays, so picking several interests
  // does not make it vanish after the first tap.
  bool _askedInterests = false;

  @override
  void initState() {
    super.initState();
    _handleAsk();
  }

  @override
  void didUpdateWidget(ExplorePlacesLanding oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.askInterests) _handleAsk();
  }

  void _handleAsk() {
    if (!widget.askInterests) return;
    _askedInterests = true;
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => widget.onAskHandled?.call(),
    );
  }

  // The derived chapters, rebuilt only when one of their inputs changes.
  ExploreLandingData? _data;
  List<Object?> _inputs = const [];

  ExploreLandingData _dataFor(
    List<Object?> inputs,
    ExploreLandingData Function() make,
  ) {
    final stale =
        _data == null ||
        inputs.length != _inputs.length ||
        [
          for (var i = 0; i < inputs.length; i++) inputs[i] != _inputs[i],
        ].contains(true);
    if (stale) {
      _data = make();
      _inputs = inputs;
    }
    return _data!;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.noInterests) _askedInterests = true;
    final interests = switch (ref.watch(myInterestsProvider)) {
      AsyncData(:final value) => value.interests,
      _ => const <PlaceInterest>[],
    };
    final matcher = ref.watch(interestMatcherProvider);
    final nearby = ref.watch(exploreNearbyProvider).value ?? const [];
    final rotation = ref.watch(exploreHeadlineRotationProvider).value ?? 0;
    final data = _dataFor(
      [
        widget.board,
        interests,
        matcher,
        nearby,
        rotation,
        widget.locationUnavailable,
        widget.homeCountyName,
      ],
      () => ExploreLandingData.build(
        board: widget.board,
        interests: interests,
        matcher: matcher,
        nearby: nearby,
        rotation: rotation,
        locationUnavailable: widget.locationUnavailable,
        homeCountyName: widget.homeCountyName,
      ),
    );

    Widget chapter(
      String kicker,
      String title,
      List<ExploreEntry> places, {
      ExploreEntry? lead,
      String? action,
      ExploreFilters? seeAll,
      bool showHeader = true,
    }) => ExploreChapter(
      showHeader: showHeader,
      kicker: kicker,
      action: action,
      onAction: seeAll == null || widget.onSeeAll == null
          ? null
          : () => widget.onSeeAll!(seeAll),
      title: title,
      places: places,
      lead: lead,
      onOpenPlace: widget.onOpenPlace,
    );

    final homeName = widget.homeCountyName;
    final nearChapter = <Widget>[
      if (nearby.isNotEmpty) ...[
        const SizedBox(height: 16),
        chapter(
          'Near you',
          'Closest to you',
          nearby,
          action: 'See all',
          seeAll: const ExploreFilters(maxKm: 250),
        ),
      ] else if (data.homePlaces.isNotEmpty) ...[
        const SizedBox(height: 16),
        chapter(
          'Your home county',
          homeName!,
          data.homePlaces,
          action: 'See all',
          seeAll: ExploreFilters(countyCode: data.homePlaces.first.countyCode),
        ),
      ],
    ];
    final headlineRow = data.headlineRow;
    final moreLabel = interests.isEmpty ? 'All places' : 'More places';

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverList.list(
        children: [
          if (_askedInterests)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: ExploreInterestPrompt(
                onDone: () => setState(() => _askedInterests = false),
              ),
            )
          else ...[
            ExploreHeadlineView(
              headline: data.headline,
              interestLabels: [for (final i in interests) i.label],
              onEditInterests: () => setState(() => _askedInterests = true),
              locationOff: widget.locationUnavailable,
            ),
            if (headlineRow.isNotEmpty) ...[
              const SizedBox(height: 16),
              chapter('', 'Headline places', headlineRow, showHeader: false),
            ],
          ],
          if (data.goBack.isNotEmpty) ...[
            const SizedBox(height: 16),
            chapter(
              'Go back',
              "Places you haven't been back to",
              data.goBack,
              action: 'See all',
              seeAll: const ExploreFilters(maxKm: 250),
            ),
            ExploreGoBackCounties(
              board: widget.board,
              onSeeAll: widget.onSeeCounties,
              onOpenCounty: widget.onOpenCounty,
            ),
          ],
          if (data.forYou.isNotEmpty) const ExploreGroupLabel('For you'),
          for (final (i, row) in data.forYou.indexed) ...[
            SizedBox(height: i == 0 ? 0 : 16),
            chapter(
              '',
              _capitalise(row.group.interest.shortName),
              row.places,
              action: 'See all ${row.group.total}',
              seeAll: ExploreFilters(
                typeKeys: row.group.typeKeys,
                typeKeysLabel: row.group.interest.label,
              ),
            ),
          ],
          if (data.more.isNotEmpty) ExploreGroupLabel(moreLabel),
          for (final (i, group) in data.more.indexed) ...[
            SizedBox(height: i == 0 ? 0 : 16),
            chapter(
              '',
              group.type.pluralLabel,
              group.places,
              action: 'See all ${group.total}',
              seeAll: ExploreFilters(typeKey: group.type.key),
            ),
          ],
          if (data.nextLead != null || data.nextBadge.isNotEmpty) ...[
            const SizedBox(height: 16),
            chapter(
              'Next badge',
              widget.locationUnavailable && homeName != null
                  ? 'Next to $homeName'
                  : 'Unclaimed counties',
              data.nextBadge,
              lead: data.nextLead,
              action: 'See all',
              seeAll: const ExploreFilters(unclaimedOnly: true),
            ),
          ],
          ...nearChapter,
          if (data.entries.isEmpty) const ExplorePlacesEmptyState(),
        ],
      ),
    );
  }

  String _capitalise(String text) =>
      text.isEmpty ? text : text[0].toUpperCase() + text.substring(1);
}
