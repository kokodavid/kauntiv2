import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/design/app_type_scale.dart';
import '../../../core/domain/map_place.dart';
import '../../../core/services/app_current_location.dart';
import '../../../design/app_colors.dart';
import '../application/real_map_start_focus.dart';
import '../domain/map_home_models.dart';
import '../domain/map_home_nearby_cards.dart';
import '../domain/map_home_nearby_places.dart';
import 'map_home_links.dart';
import 'map_home_nearby_card_tile.dart';

/// The collapsed sheet while the user is not moving: cards for the new
/// counties and places nearest them, swipeable and advancing by itself.
/// The county cards come from the board and show at once; places join when
/// the one location read and the places are in.
class MapHomePlacesCarousel extends StatefulWidget {
  const MapHomePlacesCarousel({
    super.key,
    required this.board,
    required this.loadPlaces,
    this.onOpenCounty,
    this.onOpenPlace,
  });

  final MapHomeBoardData board;
  final Future<List<MapPlace>> Function()? loadPlaces;
  final OpenCountyDetail? onOpenCounty;
  final OpenPlaceDetail? onOpenPlace;

  /// The blue label above the cards: 14 for the text, 10 below it.
  static const headingHeight = 24.0;
  static const height = MapHomeNearbyCardTile.height + headingHeight;
  static const _gap = 10.0;
  static const _advanceEvery = Duration(seconds: 5);
  static const _pauseAfterSwipe = Duration(seconds: 12);

  @override
  State<MapHomePlacesCarousel> createState() => _MapHomePlacesCarouselState();
}

class _MapHomePlacesCarouselState extends State<MapHomePlacesCarousel> {
  PageController? _pages;
  List<MapHomeNearbyPlace> _places = const [];
  Timer? _timer;
  DateTime _pausedUntil = DateTime.fromMillisecondsSinceEpoch(0);

  /// Absolute page. The carousel loops by starting far from zero and
  /// showing card `page % count`, so it can go either way without end.
  static const _startPage = 1000;
  int _page = _startPage;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
    _timer = Timer.periodic(MapHomePlacesCarousel._advanceEvery, (_) {
      _advance();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pages?.dispose();
    super.dispose();
  }

  Set<int> get _claimed => {
    for (final badge in widget.board.countyBadges)
      if (badge.state == MapHomeCountyBadgeState.earned) badge.county.code,
  };

  Future<void> _load() async {
    final loadPlaces = widget.loadPlaces;
    if (loadPlaces == null) return;
    try {
      final (places, fix) = await (
        loadPlaces(),
        AppCurrentLocation.read(),
      ).wait;
      if (fix == null ||
          !RealMapStartFocus.isInKenya(
            latitude: fix.latitude,
            longitude: fix.longitude,
          )) {
        return;
      }
      final nearest = MapHomeNearbyPlaces.nearest(
        places: places,
        from: fix,
        claimedCountyCodes: _claimed,
        limit: MapHomeNearbyCards.maxCards,
      );
      if (mounted) setState(() => _places = nearest);
    } on Object {
      // The county cards stay on their own.
    }
  }

  void _advance() {
    final pages = _pages;
    if (!mounted || pages == null || !pages.hasClients) return;
    // Off screen (sheet expanded, another tab), just after a swipe, or with
    // reduced motion: stay where the user left it.
    if (!TickerMode.valuesOf(context).enabled ||
        MediaQuery.disableAnimationsOf(context) ||
        DateTime.now().isBefore(_pausedUntil)) {
      return;
    }
    final count = _cards.length;
    if (count < 2) return;
    unawaited(
      pages.animateToPage(
        (pages.page?.round() ?? _page) + 1,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeInOut,
      ),
    );
  }

  List<MapHomeNearbyCard> get _cards => MapHomeNearbyCards.build(
    unclaimed: widget.board.unclaimed,
    placeCounts: {
      for (final badge in widget.board.countyBadges)
        badge.county.code: badge.placeNames.length,
    },
    places: _places,
  );

  bool _onScroll(ScrollNotification note) {
    if (note is ScrollStartNotification && note.dragDetails != null) {
      _pausedUntil = DateTime.now().add(MapHomePlacesCarousel._pauseAfterSwipe);
    }
    return false;
  }

  void _open(MapHomeNearbyCard card) {
    final place = card.place;
    if (place == null) {
      final open = widget.onOpenCounty;
      if (open != null) open(context, card.county.code);
      return;
    }
    final open = widget.onOpenPlace;
    if (open != null) open(context, place.id);
  }

  @override
  Widget build(BuildContext context) {
    final cards = _cards;
    return SizedBox(
      height: MapHomePlacesCarousel.height,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: MapHomePlacesCarousel.headingHeight,
            child: Text(
              'NEAR YOU · PLAN YOUR NEXT TRIP',
              style: AppTypeScale.sectionLabel.copyWith(
                color: AppColors.accent,
              ),
            ),
          ),
          Expanded(child: _pager(cards)),
        ],
      ),
    );
  }

  Widget _pager(List<MapHomeNearbyCard> cards) {
    return SizedBox(
      height: MapHomeNearbyCardTile.height,
      child: LayoutBuilder(
        builder: (context, constraints) {
          // One card plus its gap per page, so each swipe lands a card at the
          // left edge with the next one peeking in.
          final fraction =
              ((MapHomeNearbyCardTile.width + MapHomePlacesCarousel._gap) /
                      constraints.maxWidth)
                  .clamp(0.5, 1.0);
          final existing = _pages;
          if (existing == null || existing.viewportFraction != fraction) {
            if (existing != null) {
              WidgetsBinding.instance.addPostFrameCallback(
                (_) => existing.dispose(),
              );
            }
            _pages = PageController(
              viewportFraction: fraction,
              initialPage: cards.length < 2 ? 0 : _page,
            );
          }
          return NotificationListener<ScrollNotification>(
            onNotification: _onScroll,
            child: PageView.builder(
              controller: _pages,
              padEnds: false,
              // Endless when there is more than one card; null item count.
              itemCount: cards.length < 2 ? cards.length : null,
              onPageChanged: (page) => _page = page,
              itemBuilder: (context, index) {
                final card = cards[index % cards.length];
                return Align(
                  alignment: Alignment.centerLeft,
                  child: MapHomeNearbyCardTile(
                    card: card,
                    onTap: () => _open(card),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
