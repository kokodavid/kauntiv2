import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import '../../../design/app_colors.dart';
import '../data/map_home_view_preference.dart';
import '../domain/map_home_models.dart';
import '../../../core/domain/map_place.dart';
import 'map_home_county_map.dart';
import 'map_home_detection_paused_chip.dart';
import 'map_home_for_you_section.dart';
import 'map_home_links.dart';
import 'map_home_map_status.dart';
import 'map_home_sheet.dart';
import 'map_home_sheet_cards.dart';
import 'map_home_skeleton.dart';
import 'map_home_stat_card.dart';
import 'real_map_controls.dart';
import 'real_map_view.dart';

class MapHomeBoard extends StatefulWidget {
  const MapHomeBoard({
    super.key,
    required this.data,
    this.loadMapPlaces,
    this.mapboxAccessToken = '',
    this.onOpenCounty,
    this.onOpenPlace,
    this.onRoute,
    this.onPlaceRoute,
    this.onPromotedPlaceRoute,
    this.onSeeAllUnclaimed,
    this.onOpenProfile,
  });

  /// Null while the board is loading: every slot shows a same-sized
  /// placeholder, then crossfades to the real content in place.
  final MapHomeBoardData? data;

  /// Place pins for the real map.
  final Future<List<MapPlace>> Function()? loadMapPlaces;

  /// Empty (or web, which Mapbox doesn't support): drawn map only.
  final String mapboxAccessToken;

  /// County / Place Detail, supplied from `app/`; null keeps the peeks.
  final OpenCountyDetail? onOpenCounty;
  final OpenPlaceDetail? onOpenPlace;
  final OpenDirections? onRoute;
  final OpenPlaceDirections? onPlaceRoute;
  final OpenPromotedPlaceDirections? onPromotedPlaceRoute;
  final OpenAllUnclaimed? onSeeAllUnclaimed;
  final VoidCallback? onOpenProfile;

  @override
  State<MapHomeBoard> createState() => _MapHomeBoardState();
}

class _MapHomeBoardState extends State<MapHomeBoard> {
  /// Ephemeral UI state: collapses the stat card while the map is browsed.
  bool _isMapInteracting = false;

  /// The real (Mapbox) map is Home's default; the drawn map is the
  /// fallback when it can't load. Once failed, Home stays on the drawn map
  /// until the user retries, so a patchy signal never flips maps mid-use.
  _RealMapStatus _realMap = _RealMapStatus.loading;
  int _realMapAttempt = 0;

  /// The user's own choice of map, independent of [_realMap]'s load/fail
  /// state: the real map still loads normally underneath (so switching
  /// back is instant), it's just not the one shown while this is true.
  /// Loaded from storage on first build and persisted on every toggle.
  bool _preferDrawnMap = false;
  final _viewPreference = const MapHomeViewPreference();

  bool get _realMapAllowed => !kIsWeb && widget.mapboxAccessToken.isNotEmpty;

  static const _fade = Duration(milliseconds: 400);

  @override
  void initState() {
    super.initState();
    unawaited(
      _viewPreference.preferDrawnMap().then((preferDrawn) {
        if (mounted && preferDrawn) {
          setState(() => _preferDrawnMap = preferDrawn);
        }
      }),
    );
  }

  void _setPreferDrawnMap(bool preferDrawn) {
    setState(() => _preferDrawnMap = preferDrawn);
    unawaited(_viewPreference.setPreferDrawnMap(preferDrawn));
  }

  /// Where the header (top bar + stat card) ends, in board coordinates;
  /// the real map keeps its controls and camera framing below it.
  final _headerKey = GlobalKey();
  double _headerBottom = 0;

  void _measureHeader() {
    final header = _headerKey.currentContext?.findRenderObject() as RenderBox?;
    final board = context.findRenderObject() as RenderBox?;
    if (header == null || board == null || !header.hasSize) return;
    final bottom = header
        .localToGlobal(Offset(0, header.size.height), ancestor: board)
        .dy;
    if ((bottom - _headerBottom).abs() < 1) return;
    setState(() => _headerBottom = bottom);
  }

  /// The drawn map's slot below the header: the placeholder while the board
  /// or the real map loads, else the drawn county map (fallback).
  Widget _drawnMapFor(MapHomeBoardData? data, {required bool realLoading}) {
    if (data == null || realLoading) return const MapHomeLoadingMap();
    return MapHomeCountyMap(
      badges: data.countyBadges,
      homeCountySlug: data.homeCounty?.slug,
      onOpenCounty: widget.onOpenCounty,
      onInteractingChanged: (interacting) {
        if (interacting == _isMapInteracting) return;
        setState(() => _isMapInteracting = interacting);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    final mountReal =
        data != null && _realMapAllowed && _realMap != _RealMapStatus.failed;
    final realReady = mountReal && _realMap == _RealMapStatus.ready;
    // What's actually on screen: the real map once it's ready, unless the
    // user has chosen the drawn map themselves.
    final showRealMap = realReady && !_preferDrawnMap;
    // Only the automatic path should wait on the real map before showing
    // the drawn map's real content (so a fallback never flashes it right
    // before the real map turns out to succeed); a manual pick shouldn't
    // wait on it at all.
    final waitingOnRealMap =
        mountReal && _realMap == _RealMapStatus.loading && !_preferDrawnMap;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _measureHeader();
    });
    return Stack(
      children: [
        // The real map runs edge to edge; the header floats on it.
        if (mountReal) ...[
          Positioned.fill(
            child: RealMapView(
              key: ValueKey('real-map-$_realMapAttempt'),
              accessToken: widget.mapboxAccessToken,
              badges: data.countyBadges,
              homeCountySlug: data.homeCounty?.slug,
              loadPlaces: widget.loadMapPlaces,
              topInset: _headerBottom + 20,
              onReady: () => setState(() => _realMap = _RealMapStatus.ready),
              onFailed: () => setState(() => _realMap = _RealMapStatus.failed),
              onOpenCounty: widget.onOpenCounty,
              onOpenPlace: widget.onOpenPlace,
              onRoute: widget.onRoute,
              onPlaceRoute: widget.onPlaceRoute,
            ),
          ),
          const MapHomeHeaderScrim(),
          // Opaque page background behind everything until the real map's
          // style is up (so its blank canvas never flashes) or whenever
          // it's not the map being shown at all — covering the header
          // area too, which the drawn map's own layer below can't reach.
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedOpacity(
                opacity: showRealMap ? 0 : 1,
                duration: _fade,
                child: const ColoredBox(color: AppColors.pageBackground),
              ),
            ),
          ),
        ],
        Positioned.fill(
          child: SafeArea(
            bottom: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Equal top and side margin around the card, so it sits
                // a little inset from the screen edges on every side.
                const SizedBox(height: 12),
                Padding(
                  key: _headerKey,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: AnimatedSwitcher(
                    duration: _fade,
                    child: data == null
                        ? MapHomeStatCard.loading(
                            onOpenProfile: widget.onOpenProfile,
                          )
                        : MapHomeStatCard(
                            key: const ValueKey('stat-card'),
                            exploredCount: data.exploredCount,
                            totalCounties: data.totalCounties,
                            compact: _isMapInteracting,
                            tier: data.tier,
                            onOpenProfile: widget.onOpenProfile,
                          ),
                  ),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: IgnorePointer(
                          ignoring: showRealMap,
                          child: AnimatedOpacity(
                            opacity: showRealMap ? 0 : 1,
                            duration: _fade,
                            child: AnimatedSwitcher(
                              duration: _fade,
                              child: _drawnMapFor(
                                data,
                                realLoading: waitingOnRealMap,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 8,
                        left: 24,
                        right: 24,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const MapHomeDetectionPausedChip(),
                            if (data != null &&
                                _realMapAllowed &&
                                _realMap == _RealMapStatus.failed) ...[
                              const SizedBox(height: 6),
                              MapHomeOfflineMapChip(
                                onRetry: () => setState(() {
                                  _realMap = _RealMapStatus.loading;
                                  _realMapAttempt++;
                                  _isMapInteracting = false;
                                }),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        // Always on top of both map layers (even when the drawn map is
        // covering RealMapView's own controls underneath), so the user
        // can get back to whichever map they're not currently viewing.
        if (mountReal)
          Positioned(
            top:
                _headerBottom +
                20 +
                8 +
                (_preferDrawnMap ? 0 : 3 * 48),
            right: 16,
            child: RealMapRoundButton(
              icon: _preferDrawnMap ? Icons.public : Icons.map_outlined,
              tooltip: _preferDrawnMap
                  ? 'Switch to live map'
                  : 'Switch to simple map',
              active: _preferDrawnMap,
              onPressed: () => _setPreferDrawnMap(!_preferDrawnMap),
            ),
          ),
        MapHomeSheet(
          children: [
            AnimatedSwitcher(
              duration: _fade,
              child: data == null
                  ? const MapHomeForYouSkeleton()
                  : MapHomeForYouSection(
                      data: data,
                      onOpenCounty: widget.onOpenCounty,
                      onOpenPlace: widget.onOpenPlace,
                      onRoute: widget.onRoute,
                      onPromotedPlaceRoute: widget.onPromotedPlaceRoute,
                      onSeeAllUnclaimed: widget.onSeeAllUnclaimed,
                    ),
            ),
            const MapHomeQuestPreviewCard(),
          ],
        ),
      ],
    );
  }
}

enum _RealMapStatus { loading, ready, failed }
