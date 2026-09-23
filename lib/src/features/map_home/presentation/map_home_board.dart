import 'package:flutter/material.dart';

import '../../../core/widgets/app_bottom_nav.dart';
import '../domain/map_home_models.dart';
import 'map_home_county_map.dart';
import 'map_home_for_you_section.dart';
import 'map_home_sheet.dart';
import 'map_home_sheet_cards.dart';
import 'map_home_stat_card.dart';
import 'map_home_top_bar.dart';

class MapHomeBoard extends StatefulWidget {
  const MapHomeBoard({super.key, required this.data});

  final MapHomeBoardData data;

  @override
  State<MapHomeBoard> createState() => _MapHomeBoardState();
}

class _MapHomeBoardState extends State<MapHomeBoard> {
  /// Ephemeral UI state: collapses the stat card while the map is browsed.
  bool _isMapInteracting = false;

  MapHomeBoardData get data => widget.data;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    MapHomeTopBar(tierLabel: data.tierLabel),
                    const SizedBox(height: 16),
                    MapHomeStatCard(
                      exploredCount: data.exploredCount,
                      totalCounties: data.totalCounties,
                      compact: _isMapInteracting,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: MapHomeCountyMap(
                  badges: data.countyBadges,
                  homeCountySlug: data.homeCounty?.slug,
                  onInteractingChanged: (interacting) {
                    if (interacting == _isMapInteracting) return;
                    setState(() => _isMapInteracting = interacting);
                  },
                ),
              ),
            ],
          ),
        ),
        MapHomeSheet(
          children: [
            MapHomeForYouSection(suggestions: data.suggestions),
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
