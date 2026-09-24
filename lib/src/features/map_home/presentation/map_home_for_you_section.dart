import 'package:flutter/material.dart';

import '../../../core/design/app_type_scale.dart';
import '../../../design/app_colors.dart';
import '../domain/map_home_models.dart';
import 'map_home_featured_suggestion.dart';
import 'map_home_links.dart';
import 'map_home_skeleton.dart';
import 'map_home_suggestion_media.dart';

class MapHomeForYouSection extends StatelessWidget {
  const MapHomeForYouSection({
    super.key,
    required this.suggestions,
    this.onOpenCounty,
    this.onRoute,
  });

  final List<MapHomeSuggestion> suggestions;
  final OpenCountyDetail? onOpenCounty;

  /// Opens directions for the Route buttons; they're hidden when null.
  final OpenDirections? onRoute;

  @override
  Widget build(BuildContext context) {
    if (suggestions.isEmpty) return const SizedBox.shrink();

    final featured = suggestions.first;
    final rest = suggestions.length > 1
        ? suggestions.sublist(1)
        : const <MapHomeSuggestion>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const MapHomeForYouHeader(),
        const SizedBox(height: 10),
        MapHomeFeaturedSuggestion(
          suggestion: featured,
          onOpenCounty: onOpenCounty,
          onRoute: onRoute,
        ),
        if (rest.isNotEmpty) ...[
          const SizedBox(height: 12),
          SizedBox(
            height: 188,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(bottom: 4),
              itemCount: rest.length,
              separatorBuilder: (context, index) => const SizedBox(width: 10),
              itemBuilder: (context, index) => _CompactSuggestionCard(
                suggestion: rest[index],
                onOpenCounty: onOpenCounty,
                onRoute: onRoute,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class MapHomeForYouHeader extends StatelessWidget {
  const MapHomeForYouHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return const Text(
      'FOR YOU - YOUR NEXT BEST MOVE',
      style: AppTypeScale.sectionLabel,
    );
  }
}

/// Loading placeholder shaped like the featured suggestion card.
class MapHomeForYouSkeleton extends StatelessWidget {
  const MapHomeForYouSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const MapHomeForYouHeader(),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: AppColors.cardBorder),
            borderRadius: BorderRadius.circular(24),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              MapHomeSkeletonBlock(height: 168, radius: 20),
              Padding(
                padding: EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    MapHomeSkeletonBlock(width: 180, height: 16),
                    SizedBox(height: 12),
                    MapHomeSkeletonBlock(width: 220, height: 12),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CompactSuggestionCard extends StatelessWidget {
  const _CompactSuggestionCard({
    required this.suggestion,
    this.onOpenCounty,
    this.onRoute,
  });

  final MapHomeSuggestion suggestion;
  final OpenCountyDetail? onOpenCounty;
  final OpenDirections? onRoute;

  @override
  Widget build(BuildContext context) {
    return MapHomeSuggestionTapTarget(
      suggestion: suggestion,
      onOpenCounty: onOpenCounty,
      child: SizedBox(
        width: 200,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: MapHomeSuggestionPhotoHeader(
                suggestion: suggestion,
                height: 148,
              ),
            ),
            if (onRoute case final route?) ...[
              const SizedBox(height: 4),
              InkWell(
                onTap: () => openSuggestionRoute(context, suggestion, route),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Route', style: AppTypeScale.action),
                      const SizedBox(width: 2),
                      const Icon(
                        Icons.chevron_right,
                        size: 16,
                        color: AppColors.accent,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
