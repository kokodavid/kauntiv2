import 'package:flutter/material.dart';

import '../../../core/design/app_type_scale.dart';
import '../../../design/app_colors.dart';
import '../../../widgets/app_county_shape.dart';
import '../domain/map_home_models.dart';
import 'map_home_links.dart';
import 'map_home_suggestion_media.dart';

/// For You's featured card ("Your next best move"): an inset photo with
/// the place (or county) name and a Route button; below it the county,
/// why it's suggested and how far, its stats, and the county shape.
class MapHomeFeaturedSuggestion extends StatelessWidget {
  const MapHomeFeaturedSuggestion({
    super.key,
    required this.suggestion,
    this.onOpenCounty,
    this.onRoute,
  });

  final MapHomeSuggestion suggestion;
  final OpenCountyDetail? onOpenCounty;
  final OpenDirections? onRoute;

  @override
  Widget build(BuildContext context) {
    final route = onRoute;
    final stats = suggestion.stats;

    return MapHomeSuggestionTapTarget(
      suggestion: suggestion,
      onOpenCounty: onOpenCounty,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppColors.cardBorder),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: MapHomeSuggestionPhotoHeader(
                suggestion: suggestion,
                height: 136,
                showReasonPill: false,
                trailing: route == null
                    ? null
                    : MapHomeRouteButton(
                        onPressed: () =>
                            openSuggestionRoute(context, suggestion, route),
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 6, 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _Details(suggestion: suggestion, stats: stats),
                  ),
                  const SizedBox(width: 12),
                  _CountyTile(suggestion: suggestion),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Details extends StatelessWidget {
  const _Details({required this.suggestion, required this.stats});

  final MapHomeSuggestion suggestion;
  final List<({String value, String label})> stats;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '${suggestion.county.name} County',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTypeScale.compactTitle,
        ),
        const SizedBox(height: 2),
        Text(
          '${suggestion.reasonLabel} · ${suggestion.distanceAway}',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: AppTypeScale.small,
        ),
        if (stats.isNotEmpty) ...[
          const SizedBox(height: 8),
          const Divider(height: 1, color: AppColors.trackInactive),
          const SizedBox(height: 8),
          Row(
            children: [
              for (final (i, stat) in stats.indexed) ...[
                if (i > 0) const SizedBox(width: 16),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        stat.value,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypeScale.compactStatValue,
                      ),
                      Text(stat.label, style: AppTypeScale.compactStatLabel),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ],
      ],
    );
  }
}

/// The county's shape in a white squircle (County Detail's treatment).
class _CountyTile extends StatelessWidget {
  const _CountyTile({required this.suggestion});

  final MapHomeSuggestion suggestion;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      height: 72,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.countyShapeCardBorder),
        borderRadius: BorderRadius.circular(18),
      ),
      child: AppCountyShape(
        county: suggestion.county,
        fill: AppColors.accent,
      ),
    );
  }
}
