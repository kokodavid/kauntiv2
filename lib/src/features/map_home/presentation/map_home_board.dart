import 'package:flutter/material.dart';

import '../../../core/widgets/app_bottom_nav.dart';
import '../domain/map_home_models.dart';
import '../domain/map_place.dart';
import 'map_home_county_map.dart';
import 'map_home_for_you_section.dart';
import 'map_home_sheet.dart';
import 'map_home_sheet_cards.dart';
import 'map_home_skeleton.dart';
import 'map_home_stat_card.dart';
import 'map_home_top_bar.dart';
import 'map_home_map_mode_toggle.dart';
import 'pro_map_view.dart';

class MapHomeBoard extends StatefulWidget {
  const MapHomeBoard({super.key, required this.data, this.loadMapPlaces});

  /// Null while the board is loading: every slot shows a same-sized
  /// placeholder, then crossfades to the real content in place.
  final MapHomeBoardData? data;

  /// SPIKE: place pins for the Pro map preview.
  final Future<List<MapPlace>> Function()? loadMapPlaces;

  @override
  State<MapHomeBoard> createState() => _MapHomeBoardState();
}

class _MapHomeBoardState extends State<MapHomeBoard> {
  /// Ephemeral UI state: collapses the stat card while the map is browsed.
  bool _isMapInteracting = false;

  /// SPIKE: Mapbox map in place of the drawn one (ephemeral UI state).
  bool _showRealMap = false;

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

  /// The drawn map's slot below the header: placeholder while loading,
  /// then the drawn county map. (The real map sits behind the whole board.)
  Widget _drawnMapFor(MapHomeBoardData? data) {
    if (data == null) return const MapHomeLoadingMap();
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
    final showRealMap = data != null && _showRealMap;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _measureHeader();
    });
    return Stack(
      children: [
        // SPIKE: the real map runs edge to edge; the header floats on it.
        if (showRealMap) ...[
          Positioned.fill(
            child: ProMapView(
              key: const ValueKey('real-map'),
              accessToken: ProMapView.configuredAccessToken,
              badges: data.countyBadges,
              homeCountySlug: data.homeCounty?.slug,
              loadPlaces: widget.loadMapPlaces,
              topInset: _headerBottom + 20,
            ),
          ),
          const MapHomeHeaderScrim(),
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
                      if (!showRealMap)
                        Positioned.fill(
                          child: AnimatedSwitcher(
                            duration: _fade,
                            child: _drawnMapFor(data),
                          ),
                        ),
                      // SPIKE: Map / Real switch, only with a Mapbox token.
                      if (data != null && ProMapView.isAvailable)
                        Positioned(
                          top: 8,
                          left: 24,
                          child: MapHomeMapModeToggle(
                            showRealMap: _showRealMap,
                            onChanged: (real) => setState(() {
                              _showRealMap = real;
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
