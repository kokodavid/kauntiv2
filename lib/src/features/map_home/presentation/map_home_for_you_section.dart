import 'package:flutter/material.dart';

import '../../../design/app_colors.dart';
import '../../../design/app_text_styles.dart';
import '../domain/map_home_models.dart';
import 'map_home_suggestion_media.dart';

class MapHomeForYouSection extends StatelessWidget {
  const MapHomeForYouSection({super.key, required this.suggestions});

  final List<MapHomeSuggestion> suggestions;

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
        const Text(
          'FOR YOU - YOUR NEXT BEST MOVE',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.7,
            color: AppColors.mutedForeground,
          ),
        ),
        const SizedBox(height: 10),
        _FeaturedSuggestionCard(suggestion: featured),
        if (rest.isNotEmpty) ...[
          const SizedBox(height: 12),
          SizedBox(
            height: 188,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(bottom: 4),
              itemCount: rest.length,
              separatorBuilder: (context, index) => const SizedBox(width: 10),
              itemBuilder: (context, index) =>
                  _CompactSuggestionCard(suggestion: rest[index]),
            ),
          ),
        ],
      ],
    );
  }
}

class _FeaturedSuggestionCard extends StatelessWidget {
  const _FeaturedSuggestionCard({required this.suggestion});

  final MapHomeSuggestion suggestion;

  @override
  Widget build(BuildContext context) {
    final stats = suggestion.statLabels.toList();

    return MapHomeSuggestionTapTarget(
      suggestion: suggestion,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppColors.cardBorder),
          borderRadius: BorderRadius.circular(20),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            MapHomeSuggestionPhotoHeader(suggestion: suggestion, height: 158),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${suggestion.reasonLabel} . ${suggestion.distanceAway}',
                          style: AppTextStyles.listItemTitle,
                        ),
                        if (stats.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          const Divider(height: 1, color: AppColors.trackInactive),
                          const SizedBox(height: 10),
                          MapHomeSuggestionStatsRow(stats: stats),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  MapHomeSuggestionCountySwatch(county: suggestion.county),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CompactSuggestionCard extends StatelessWidget {
  const _CompactSuggestionCard({required this.suggestion});

  final MapHomeSuggestion suggestion;

  @override
  Widget build(BuildContext context) {
    return MapHomeSuggestionTapTarget(
      suggestion: suggestion,
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
            const SizedBox(height: 8),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Route',
                  style: AppTextStyles.buttonLabel.copyWith(
                    color: AppColors.accent,
                  ),
                ),
                const SizedBox(width: 2),
                const Icon(
                  Icons.chevron_right,
                  size: 16,
                  color: AppColors.accent,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
