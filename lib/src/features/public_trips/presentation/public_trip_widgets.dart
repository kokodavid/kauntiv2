import 'package:flutter/material.dart';

import '../../../design/app_colors.dart';
import '../../../design/app_text_styles.dart';

/// A section heading with an optional trailing note, shared by the review
/// screens.
class PublicTripSectionTitle extends StatelessWidget {
  const PublicTripSectionTitle(this.title, {super.key, this.trailing});

  final String title;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 22, bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: AppTextStyles.detailSectionTitle),
          if (trailing != null) Text(trailing!, style: AppTextStyles.bodySmall),
        ],
      ),
    );
  }
}

/// A rounded note box for explanations and errors.
class PublicTripNote extends StatelessWidget {
  const PublicTripNote(this.text, {super.key, this.isError = false});

  final String text;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isError
            ? AppColors.danger.withValues(alpha: 0.08)
            : AppColors.noteBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: AppTextStyles.noteText.copyWith(
          color: isError ? AppColors.dangerSoftForeground : null,
        ),
      ),
    );
  }
}

/// The full-width blue action button used at the bottom of the screens.
class PublicTripPrimaryButton extends StatelessWidget {
  const PublicTripPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.busy = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: FilledButton(
        onPressed: busy ? null : onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: AppColors.accentForeground,
          disabledBackgroundColor: AppColors.secondaryFill,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: busy
            ? const SizedBox.square(
                dimension: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Text(
                label,
                style: AppTextStyles.buttonLabel.copyWith(
                  color: onPressed == null
                      ? AppColors.mutedForeground
                      : AppColors.accentForeground,
                ),
              ),
      ),
    );
  }
}

/// "12 Mar 2026", without a time of day: the public trip never shows one.
String publicTripDateLabel(DateTime date) {
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec', //
  ];
  return '${date.day} ${months[date.month - 1]} ${date.year}';
}
