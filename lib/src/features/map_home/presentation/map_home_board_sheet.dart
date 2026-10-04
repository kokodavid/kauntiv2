import 'package:flutter/material.dart';

import '../domain/map_home_models.dart';
import 'map_home_for_you_section.dart';
import 'map_home_links.dart';
import 'map_home_sheet.dart';
import 'map_home_sheet_cards.dart';

/// Home's bottom sheet: For You (a placeholder while [data] loads), then
/// [extra] - a section another feature adds, which hides itself when it has
/// nothing to show - then the quest preview.
class MapHomeBoardSheet extends StatelessWidget {
  const MapHomeBoardSheet({
    super.key,
    required this.data,
    required this.fade,
    this.extra,
    this.onOpenCounty,
    this.onOpenPlace,
    this.onRoute,
    this.onPromotedPlaceRoute,
    this.onSeeAllUnclaimed,
  });

  final MapHomeBoardData? data;
  final Duration fade;
  final Widget? extra;
  final OpenCountyDetail? onOpenCounty;
  final OpenPlaceDetail? onOpenPlace;
  final OpenDirections? onRoute;
  final OpenPromotedPlaceDirections? onPromotedPlaceRoute;
  final OpenAllUnclaimed? onSeeAllUnclaimed;

  @override
  Widget build(BuildContext context) {
    final board = data;
    return MapHomeSheet(
      children: [
        AnimatedSwitcher(
          duration: fade,
          child: board == null
              ? const MapHomeForYouSkeleton()
              : MapHomeForYouSection(
                  data: board,
                  onOpenCounty: onOpenCounty,
                  onOpenPlace: onOpenPlace,
                  onRoute: onRoute,
                  onPromotedPlaceRoute: onPromotedPlaceRoute,
                  onSeeAllUnclaimed: onSeeAllUnclaimed,
                ),
        ),
        ?extra,
        const MapHomeQuestPreviewCard(),
      ],
    );
  }
}
