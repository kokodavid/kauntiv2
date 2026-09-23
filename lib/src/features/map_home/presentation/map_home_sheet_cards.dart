import 'package:flutter/material.dart';

import '../../../design/app_colors.dart';
import '../../../design/app_text_styles.dart';

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
