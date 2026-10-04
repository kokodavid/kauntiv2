import 'package:flutter/material.dart';

import '../../../design/app_colors.dart';
import '../../../design/app_text_styles.dart';
import '../domain/public_trip_moment_kind.dart';
import '../domain/public_trip_view.dart';
import 'public_trip_author_header.dart';
import 'public_trip_format.dart';
import 'public_trip_viewer_photos.dart';
import 'public_trip_widgets.dart';

/// Opens a directions app at a point. The app wires this to its directions
/// launcher, so these screens never know how.
typedef OpenPublicTripDirections = void Function(double lat, double lng);

/// Everything below the map on a public trip: title, author, key facts,
/// directions, the chosen moments and photos, and the report / block menu.
class PublicTripScreenBody extends StatelessWidget {
  const PublicTripScreenBody({
    super.key,
    required this.trip,
    required this.onReport,
    required this.onBlock,
    this.onOpenDirections,
  });

  final PublicTripView trip;
  final OpenPublicTripDirections? onOpenDirections;
  final VoidCallback onReport;
  final VoidCallback onBlock;

  @override
  Widget build(BuildContext context) {
    final start = trip.publicStart;
    final directions = onOpenDirections;
    final counties = publicTripCountyNames(trip);
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 40),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(trip.title, style: AppTextStyles.detailTitle),
            ),
            PopupMenuButton<VoidCallback>(
              tooltip: 'More',
              icon: const Icon(Icons.more_horiz),
              onSelected: (action) => action(),
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: onReport,
                  child: const Text('Report this trip'),
                ),
                PopupMenuItem(
                  value: onBlock,
                  child: Text('Block ${trip.author.displayName}'),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        PublicTripAuthorHeader(trip: trip),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _Fact(
              icon: publicTripModeIcon(trip),
              label: publicTripModeLabel(trip),
            ),
            _Fact(
              icon: Icons.route_outlined,
              label: publicTripDistanceLabel(trip.distanceMeters),
            ),
            _Fact(
              icon: Icons.map_outlined,
              label: publicTripCountyCountLabel(trip),
            ),
          ],
        ),
        if (counties.isNotEmpty) ...[
          const SizedBox(height: 10),
          Text(counties, style: AppTextStyles.bodySmall),
        ],
        if (start != null && directions != null) ...[
          const SizedBox(height: 18),
          PublicTripPrimaryButton(
            label: 'Directions to the start',
            onPressed: () => directions(start.latitude, start.longitude),
          ),
          const PublicTripNote(
            'The start shown here is a little way along the route, not where '
            'the trip really began.',
          ),
        ],
        if (trip.moments.isNotEmpty) ...[
          const PublicTripSectionTitle('Along the way'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final entry in _momentCounts(trip).entries)
                _Fact(
                  icon: Icons.place_outlined,
                  label: entry.value > 1
                      ? '${entry.value} × ${entry.key.label}'
                      : entry.key.label,
                ),
            ],
          ),
        ],
        PublicTripViewerPhotos(trip: trip),
      ],
    );
  }

  static Map<PublicTripMomentKind, int> _momentCounts(PublicTripView trip) {
    final counts = <PublicTripMomentKind, int>{};
    for (final moment in trip.moments) {
      counts.update(moment.kind, (n) => n + 1, ifAbsent: () => 1);
    }
    return counts;
  }
}

class _Fact extends StatelessWidget {
  const _Fact({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.noteBackground,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.mutedForeground),
          const SizedBox(width: 6),
          Text(label, style: AppTextStyles.chipLabel),
        ],
      ),
    );
  }
}
