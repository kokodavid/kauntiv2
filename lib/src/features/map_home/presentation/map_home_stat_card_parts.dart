part of 'map_home_stat_card.dart';

/// What the three colours on the map mean, with the share of Kenya
/// explored on the right (left out in the compact form, which shows it
/// under the bar).
class _LegendRow extends StatelessWidget {
  const _LegendRow({this.percent});

  final String? percent;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const _LegendItem(color: AppColors.legendHome, label: 'Home'),
        const SizedBox(width: 16),
        const _LegendItem(color: AppColors.legendVisited, label: 'Visited'),
        const SizedBox(width: 16),
        const _LegendItem(color: AppColors.legendPassed, label: 'Passed'),
        if (percent case final share?) ...[
          const Spacer(),
          Text(share, style: AppTextStyles.bodySmall),
        ],
      ],
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
        // Figma draws the legend swatch as a slightly rounded square
        // (10px, 3px corner radius), not a circle.
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 5),
        Text(label, style: AppTextStyles.bodySmall),
      ],
    );
  }
}
