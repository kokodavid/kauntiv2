import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import '../../../core/widgets/app_bottom_nav.dart';
import '../../../design/app_colors.dart';
import '../domain/map_home_models.dart';
import '../domain/map_place.dart';
import 'map_home_county_map.dart';
import 'map_home_for_you_section.dart';
import 'map_home_map_status.dart';
import 'map_home_sheet.dart';
import 'map_home_sheet_cards.dart';
import 'map_home_skeleton.dart';
import 'map_home_stat_card.dart';
import 'map_home_top_bar.dart';
import 'real_map_view.dart';

class MapHomeBoard extends StatefulWidget {
  const MapHomeBoard({
    super.key,
    required this.data,
    this.loadMapPlaces,
    this.mapboxAccessToken = '',
  });

  /// Null while the board is loading: every slot shows a same-sized
  /// placeholder, then crossfades to the real content in place.
  final MapHomeBoardData? data;

  /// Place pins for the real map.
  final Future<List<MapPlace>> Function()? loadMapPlaces;

  /// Empty (or web, which Mapbox doesn't support): drawn map only.
  final String mapboxAccessToken;

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

  bool get _realMapAllowed => !kIsWeb && widget.mapboxAccessToken.isNotEmpty;

  static const _fade = Duration(milliseconds: 400);

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
            ),
          ),
          const MapHomeHeaderScrim(),
          // Page background over the map until its style is up, so its
          // blank canvas never flashes; fades out when ready.
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedOpacity(
                opacity: realReady ? 0 : 1,
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
                const SizedBox(height: 16),
                Padding(
                  key: _headerKey,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      MapHomeTopBar(tierLabel: data?.tierLabel),
                      const SizedBox(height: 16),
                      AnimatedSwitcher(
                        duration: _fade,
                        child: data == null
                            ? const MapHomeStatCard.loading()
                            : MapHomeStatCard(
                                key: const ValueKey('stat-card'),
                                exploredCount: data.exploredCount,
                                totalCounties: data.totalCounties,
                                compact: _isMapInteracting,
                              ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: IgnorePointer(
                          ignoring: realReady,
                          child: AnimatedOpacity(
                            opacity: realReady ? 0 : 1,
                            duration: _fade,
                            child: AnimatedSwitcher(
                              duration: _fade,
                              child: _drawnMapFor(data, realLoading: mountReal),
                            ),
                          ),
                        ),
                      ),
                      if (data != null &&
                          _realMapAllowed &&
                          _realMap == _RealMapStatus.failed)
                        Positioned(
                          top: 8,
                          left: 24,
                          child: MapHomeOfflineMapChip(
                            onRetry: () => setState(() {
                              _realMap = _RealMapStatus.loading;
                              _realMapAttempt++;
                              _isMapInteracting = false;
                            }),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        MapHomeSheet(
          children: [
            AnimatedSwitcher(
              duration: _fade,
              child: data == null
                  ? const MapHomeForYouSkeleton()
                  : MapHomeForYouSection(suggestions: data.suggestions),
            ),
            const MapHomeQuestPreviewCard(),
          ],
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: AppBottomNav(
            selected: AppNavTab.map,
            onSelect: (tab) {
              if (tab == AppNavTab.map) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('This tab is coming next.')),
              );
            },
          ),
        ),
      ],
    );
  }
}

enum _RealMapStatus { loading, ready, failed }
