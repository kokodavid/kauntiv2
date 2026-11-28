import 'dart:async';

import 'package:flutter/material.dart';

import '../domain/map_home_compact.dart';
import 'map_home_compact_card.dart';
import 'map_home_links.dart';

/// The collapsed sheet's compact card wired to what it can do: start a Trip
/// from the home county, route to the suggestion, or open the county.
class MapHomeCompactActionCard extends StatelessWidget {
  const MapHomeCompactActionCard({
    super.key,
    required this.compact,
    this.onStartTrip,
    this.onRoute,
    this.onOpenCounty,
  });

  final MapHomeCompact compact;
  final VoidCallback? onStartTrip;
  final OpenDirections? onRoute;
  final OpenCountyDetail? onOpenCounty;

  @override
  Widget build(BuildContext context) {
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
}
