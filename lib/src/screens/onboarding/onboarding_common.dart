import 'package:flutter/material.dart';

import '../../design/app_colors.dart';
import '../../design/app_spacing.dart';
import '../../design/app_text_styles.dart';
import '../../widgets/app_google_logo.dart';
import '../../widgets/app_progress_indicator.dart';

class OnboardingAuthButton extends StatelessWidget {
  const OnboardingAuthButton({
    super.key,
    required this.label,
    this.icon,
    this.useGoogleLogo = false,
    required this.onPressed,
    this.isLoading = false,
  }) : assert(
         icon != null || useGoogleLogo,
         'Provide either icon or useGoogleLogo.',
       );

  final String label;
  final IconData? icon;
  final bool useGoogleLogo;
  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    const foregroundColor = AppColors.buttonForeground;

    return SizedBox(
      width: double.infinity,
      height: 44,
      child: OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: AppColors.secondaryFill,
          foregroundColor: foregroundColor,
          disabledBackgroundColor: AppColors.secondaryFill,
          disabledForegroundColor: foregroundColor,
          side: BorderSide.none,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          textStyle: AppTextStyles.buttonLabelSecondary,
        ),
        child: isLoading
            ? const AppProgressIndicator(color: foregroundColor, radius: 9)
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  useGoogleLogo
                      ? const AppGoogleLogo(size: 16)
                      : Icon(icon, size: 16, color: foregroundColor),
                  const SizedBox(width: AppSpacing.sm),
                  Text(label),
                ],
              ),
      ),
    );
  }
}
