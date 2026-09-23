import 'package:flutter/material.dart';

import '../../../core/widgets/app_bottom_nav.dart';
import '../domain/map_home_models.dart';
import 'map_home_county_map.dart';
import 'map_home_sheet.dart';
import 'map_home_sheet_cards.dart';
import 'map_home_stat_card.dart';
import 'map_home_top_bar.dart';

class MapHomeBoard extends StatelessWidget {
  const MapHomeBoard({super.key, required this.data});

  final MapHomeBoardData data;

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
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: MapHomeCountyMap(
                  badges: data.countyBadges,
                  homeCountySlug: data.homeCounty?.slug,
                ),
              ),
            ],
          ),
        ),
        MapHomeSheet(
          children: [
            MapHomeSheetSectionTitle(
              title: 'For you',
              action: '${data.suggestions.length} ideas',
            ),
            for (final suggestion in data.suggestions)
              MapHomeSuggestionTile(suggestion: suggestion),
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
