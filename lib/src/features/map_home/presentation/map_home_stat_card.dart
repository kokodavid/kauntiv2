import 'package:flutter/material.dart';

import '../../../design/app_colors.dart';
import '../../../design/app_text_styles.dart';

class MapHomeStatCard extends StatelessWidget {
  const MapHomeStatCard({
    super.key,
    required this.exploredCount,
    required this.totalCounties,
  });

  final int exploredCount;
  final int totalCounties;

  @override
  Widget build(BuildContext context) {
    final safeTotal = totalCounties <= 0 ? 1 : totalCounties;
    final percent = ((exploredCount / safeTotal) * 100).round();
    final left = (totalCounties - exploredCount).clamp(0, totalCounties);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.cardBorder),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
          bottomLeft: Radius.circular(10),
          bottomRight: Radius.circular(10),
        ),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFE6F3FF), Colors.white],
          stops: [0.02, 0.85],
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A606060),
            offset: Offset(0, 5),
            blurRadius: 23.5,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '$exploredCount',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 34,
                  fontWeight: FontWeight.w300,
                  color: AppColors.accent,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                'of $totalCounties counties claimed',
                style: AppTextStyles.chipLabel,
              ),
            ],
          ),
          const SizedBox(height: 6),
          _CountyTickBar(exploredCount: exploredCount, total: totalCounties),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('$percent% OF KENYA', style: AppTextStyles.bodySmall),
              Text('$left LEFT', style: AppTextStyles.bodySmall),
            ],
          ),
          const SizedBox(height: 10),
          const Row(
            children: [
              _LegendItem(color: AppColors.legendHome, label: 'Home'),
              SizedBox(width: 12),
              _LegendItem(color: AppColors.legendVisited, label: 'Visited'),
              SizedBox(width: 12),
              _LegendItem(color: AppColors.legendPassed, label: 'Passed'),
            ],
          ),
        ],
      ),
    );
  }
}

class _CountyTickBar extends StatelessWidget {
  const _CountyTickBar({required this.exploredCount, required this.total});

  final int exploredCount;
  final int total;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 20,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var i = 0; i < total; i++) ...[
            if (i > 0) const Spacer(),
            Container(
              width: 4,
              height: i < exploredCount ? 20 : 13,
              decoration: BoxDecoration(
                color: i < exploredCount
                    ? AppColors.accent
                    : AppColors.trackInactive,
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: AppTextStyles.bodySmall),
      ],
    );
  }
}
