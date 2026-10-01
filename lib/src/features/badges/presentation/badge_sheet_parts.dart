import 'package:flutter/material.dart';

import '../../../core/widgets/app_shimmer.dart';
import '../../../design/app_colors.dart';
import '../../../design/app_text_styles.dart';

/// The sheet's pill buttons (Share / View county).
class BadgeSheetButton extends StatelessWidget {
  const BadgeSheetButton({
    super.key,
    required this.label,
    required this.icon,
    required this.filled,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final bool filled;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(24),
    );
    return SizedBox(
      height: 48,
      child: filled
          ? ElevatedButton.icon(
              onPressed: onPressed,
              icon: Icon(icon, size: 18),
              label: Text(label, style: AppTextStyles.buttonLabel),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: AppColors.accentForeground,
                elevation: 0,
                shape: shape,
              ),
            )
          : OutlinedButton.icon(
              onPressed: onPressed,
              icon: Icon(icon, size: 18),
              label: Text(label, style: AppTextStyles.buttonLabelSecondary),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.foreground,
                side: const BorderSide(color: AppColors.cardBorder),
                shape: shape,
              ),
            ),
    );
  }
}

/// The grab handle at the top of the sheet.
class BadgeSheetHandle extends StatelessWidget {
  const BadgeSheetHandle({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 40,
        height: 4,
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.trackInactive,
          borderRadius: BorderRadius.circular(999),
        ),
      ),
    );
  }
}

/// The sheet's details while they load: shimmering lines and a stats block
/// in place of the sections below the badge card.
class BadgeDetailLoading extends StatelessWidget {
  const BadgeDetailLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Loading badge details',
      child: const AppShimmer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Line(width: 180),
            _Line(width: 260),
            SizedBox(height: 12),
            AppSkeleton(height: 96, radius: 16),
          ],
        ),
      ),
    );
  }
}

/// "Places to start with" while the distance lookup runs: rows shaped
/// like [AppPlaceRow] (photo, name, category and distance).
class BadgePlacesLoading extends StatelessWidget {
  const BadgePlacesLoading({super.key, this.count = 3});

  final int count;

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppSkeleton(width: 160, height: 14),
          for (var i = 0; i < count; i++)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 14),
              child: Row(
                children: [
                  AppSkeleton(width: 54, height: 54, radius: 10),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppSkeleton(width: 150, height: 14),
                        SizedBox(height: 8),
                        AppSkeleton(width: 100, height: 11),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({required this.width});

  final double width;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          const AppSkeleton(width: 18, height: 18, circle: true),
          const SizedBox(width: 10),
          AppSkeleton(width: width, height: 12),
        ],
      ),
    );
  }
}
