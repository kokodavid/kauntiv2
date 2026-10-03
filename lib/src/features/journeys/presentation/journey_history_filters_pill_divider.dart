part of 'journey_history_filters.dart';

/// A thin vertical rule separating groups of pills in the filter strip.
class _PillDivider extends StatelessWidget {
  const _PillDivider();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Container(width: 1, height: 20, color: AppColors.cardBorder),
    );
  }
}
