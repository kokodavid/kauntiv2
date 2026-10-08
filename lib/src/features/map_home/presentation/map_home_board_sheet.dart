import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/domain/map_place.dart';
import '../../../core/widgets/app_photo_parts.dart';
import '../domain/map_home_compact.dart';
import '../domain/map_home_layout.dart';
import '../domain/map_home_models.dart';
import 'map_home_celebration_card.dart';
import 'map_home_compact_card.dart';
import 'map_home_for_you_section.dart';
import 'map_home_links.dart';
import 'map_home_places_carousel.dart';
import 'map_home_sheet.dart';
import 'map_home_suggestion_media.dart';

/// Height of the collapsed "Record a Trip" card (16 + 40 + 16).
const defaultRecordTripCardHeight = 72.0;

/// Home's bottom sheet. While [data] or [layout] is null it shows a
/// placeholder; then the sections of [layout], in order, each hiding when it
/// has nothing to show. Collapsed, it is one compact card.
class MapHomeBoardSheet extends StatelessWidget {
  const MapHomeBoardSheet({
    super.key,
    required this.data,
    required this.layout,
    required this.fade,
    this.tripsNear,
    this.savedPlans,
    this.loadPlaces,
    this.recordTripCard,
    this.recordTripCardHeight = defaultRecordTripCardHeight,
    this.onStartTrip,
    this.onOpenCounty,
    this.onOpenPlace,
    this.onRoute,
    this.onPromotedPlaceRoute,
    this.onSeeAllUnclaimed,
  });

  final MapHomeBoardData? data;
  final MapHomeLayout? layout;
  final Duration fade;

  /// The public trips row, supplied by another feature; hides itself.
  final Widget? tripsNear;

  /// The user's saved plans, supplied by another feature; hides itself.
  final Widget? savedPlans;

  /// Loads every place with its position, for the places carousel.
  final Future<List<MapPlace>> Function()? loadPlaces;

  /// The one-tap "Record a Trip" card, supplied by `app/` only while the
  /// phone is moving. It takes the collapsed sheet.
  final Widget? recordTripCard;

  /// How tall [recordTripCard] is when collapsed.
  final double recordTripCardHeight;

  /// Starts a Trip, or null when Trips are not available.
  final VoidCallback? onStartTrip;
  final OpenCountyDetail? onOpenCounty;
  final OpenPlaceDetail? onOpenPlace;
  final OpenDirections? onRoute;
  final OpenPromotedPlaceDirections? onPromotedPlaceRoute;
  final OpenAllUnclaimed? onSeeAllUnclaimed;

  @override
  Widget build(BuildContext context) {
    final board = data;
    final picked = layout;
    if (board == null || picked == null) {
      return MapHomeSheet(
        children: [
          AnimatedSwitcher(
            duration: fade,
            child: const MapHomeForYouSkeleton(),
          ),
        ],
      );
    }
    final compact = MapHomeCompact.forLayout(picked, board);
    return MapHomeSheet(
      startsExpanded: MapHomeLayoutRules.startsExpanded(picked),
      collapsedHeight: recordTripCard != null
          ? recordTripCardHeight
          : _useCarousel(picked, board)
          ? MapHomePlacesCarousel.height
          : MapHomeCompactCard.height,
      collapsed: _collapsed(context, picked, board, compact),
      children: [
        for (final section in MapHomeLayoutRules.sections(picked))
          ?_section(section, picked, board),
      ],
    );
  }

  /// The carousel replaces the compact card on the standard layout when
  /// there are unclaimed counties to show (so its height is known up front).
  bool _useCarousel(MapHomeLayout layout, MapHomeBoardData board) =>
      recordTripCard == null &&
      layout == MapHomeLayout.standard &&
      board.unclaimed.isNotEmpty;

  /// Moving: the Record a Trip card. Otherwise the places carousel, or the
  /// compact card for the other layouts.
  Widget? _collapsed(
    BuildContext context,
    MapHomeLayout layout,
    MapHomeBoardData board,
    MapHomeCompact? compact,
  ) {
    if (recordTripCard != null) return recordTripCard;
    if (_useCarousel(layout, board)) {
      return MapHomePlacesCarousel(
        board: board,
        loadPlaces: loadPlaces,
        onOpenCounty: onOpenCounty,
        onOpenPlace: onOpenPlace,
      );
    }
    return compact == null ? null : _compactCard(context, compact);
  }

  Widget _compactCard(BuildContext context, MapHomeCompact compact) {
    final start = compact.isHomeStart ? onStartTrip : null;
    final route = onRoute;
    return MapHomeCompactCard(
      kicker: compact.context,
      title: compact.title,
      meta: compact.meta,
      county: compact.county,
      imageUrl: compact.imageUrl,
      buttonLabel: start != null || route == null ? 'Details' : 'Route',
      onPressed: () {
        if (start != null) return start();
        if (route != null) {
          unawaited(
            openRoute(context, compact.suggestion.directionsQuery, route),
          );
          return;
        }
        openCountyOrNote(context, compact.county, onOpenCounty);
      },
      onOpen: () => openCountyOrNote(context, compact.county, onOpenCounty),
    );
  }

  Widget? _section(
    MapHomeSection section,
    MapHomeLayout layout,
    MapHomeBoardData board,
  ) {
    switch (section) {
      case MapHomeSection.celebration:
        final claimed = board.exploredCount;
        final total = board.totalCounties;
        if (layout == MapHomeLayout.complete) {
          return MapHomeCelebrationCard(
            headline: 'All $total counties',
            meta: 'You finished Kenya. Now go deeper.',
            claimed: claimed,
            total: total,
          );
        }
        final claim = board.lastClaim;
        if (claim == null) return null;
        return MapHomeCelebrationCard(
          headline: '${claim.county.name} is yours',
          meta: '$claimed of $total claimed · ${total - claimed} to go',
          claimed: claimed,
          total: total,
        );
      case MapHomeSection.compactTarget:
        // Shown as the collapsed card; expanded, the nearest county leads.
        final nearest = board.unclaimed.firstOrNull ?? board.fallbackTop;
        if (nearest == null) return null;
        return MapHomeSuggestionTarget(
          suggestion: nearest,
          kicker: 'NEAREST UNCLAIMED',
          title: 'Your next county',
          onOpenCounty: onOpenCounty,
          onRoute: onRoute,
        );
      case MapHomeSection.homeCountyTarget:
        final home = board.homeCountySuggestion;
        if (home == null) return null;
        return MapHomeSuggestionTarget(
          suggestion: home,
          kicker: 'START HERE',
          title: 'Your home county',
          isHome: true,
          onOpenCounty: onOpenCounty,
          onRoute: onRoute,
          onStartTrip: onStartTrip,
        );
      case MapHomeSection.primaryTarget:
        if (board.promotion == null && board.fallbackTop == null) return null;
        return MapHomePrimaryTarget(
          data: board,
          onOpenCounty: onOpenCounty,
          onOpenPlace: onOpenPlace,
          onRoute: onRoute,
          onPromotedPlaceRoute: onPromotedPlaceRoute,
        );
      case MapHomeSection.nextGoal:
        final next = board.unclaimed.firstOrNull;
        if (next == null) return null;
        return MapHomeSuggestionTarget(
          suggestion: next,
          kicker: 'NEXT GOAL',
          title: 'Nearest unclaimed',
          onOpenCounty: onOpenCounty,
          onRoute: onRoute,
        );
      case MapHomeSection.nearbyUnclaimed:
        final skip = switch (layout) {
          MapHomeLayout.claim ||
          MapHomeLayout.recording => board.unclaimed.firstOrNull?.county.code,
          _ => null,
        };
        if (board.unclaimedRow.every((e) => e.county.code == skip)) {
          return null;
        }
        return MapHomeNearbyRow(
          data: board,
          skip: skip,
          onOpenCounty: onOpenCounty,
          onRoute: onRoute,
          onSeeAllUnclaimed: onSeeAllUnclaimed,
        );
      case MapHomeSection.goDeeper:
        if (board.suggestions.isEmpty) return null;
        return MapHomeGoDeeperRow(
          data: board,
          onOpenCounty: onOpenCounty,
          onRoute: onRoute,
        );
      case MapHomeSection.savedPlans:
        return savedPlans;
      case MapHomeSection.tripsNear:
        return tripsNear;
    }
  }
}
