import 'package:flutter/material.dart';

import '../../../design/app_colors.dart';
import '../../../design/app_text_styles.dart';
import '../../../widgets/app_county_shape.dart';
import '../domain/map_home_models.dart';

class MapHomeSheetSectionTitle extends StatelessWidget {
  const MapHomeSheetSectionTitle({
    super.key,
    required this.title,
    required this.action,
  });

  final String title;
  final String action;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: AppTextStyles.headingForeground),
        Text(action, style: AppTextStyles.bodySmall),
      ],
    );
  }
}

class MapHomeSuggestionTile extends StatelessWidget {
  const MapHomeSuggestionTile({super.key, required this.suggestion});

  final MapHomeSuggestion suggestion;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.cardBorder),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 48,
            height: 48,
            child: AppCountyShape(
              county: suggestion.county,
              fill: AppColors.accent.withValues(alpha: 0.14),
              stroke: AppColors.accent,
              strokeWidth: 1.2,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(suggestion.county.name, style: AppTextStyles.listItemTitle),
                Text(
                  '${suggestion.label} . ${suggestion.distanceAway}',
                  style: AppTextStyles.listItemSubtitle,
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: AppColors.mutedForeground),
        ],
      ),
    );
  }
}

class MapHomeQuestPreviewCard extends StatelessWidget {
  const MapHomeQuestPreviewCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.cardBorder),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.flag_outlined, color: AppColors.accent),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Coast before Christmas',
                  style: AppTextStyles.listItemTitle,
                ),
                Text(
                  'Side quests will connect here next.',
                  style: AppTextStyles.listItemSubtitle,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
