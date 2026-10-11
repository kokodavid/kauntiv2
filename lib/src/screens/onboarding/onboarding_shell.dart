import 'package:flutter/material.dart';

import '../../design/app_colors.dart';
import '../../design/app_text_styles.dart';
import '../../widgets/app_progress_indicator.dart';
import 'onboarding_progress_header.dart';

/// One shell for the three new-user setup steps: progress at the top, a
/// title with one line of support, the step's content, and a footer with
/// the primary button and a reserved secondary slot. The secondary slot
/// keeps its height when empty, so Continue sits at the same place on
/// every step.
class OnboardingShell extends StatelessWidget {
  const OnboardingShell({
    super.key,
    required this.step,
    required this.title,
    required this.subtitle,
    required this.child,
    required this.primaryLabel,
    required this.onPrimary,
    this.onBack,
    this.secondaryLabel,
    this.onSecondary,
    this.isBusy = false,
    this.overlay,
  });

  /// 1 to 3.
  final int step;
  final String title;

  /// Plain text, or any widget when part of the line needs emphasis.
  final Widget subtitle;
  final Widget child;
  final String primaryLabel;

  /// Null disables the primary button.
  final VoidCallback? onPrimary;
  final VoidCallback? onBack;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;

  /// True while a request is in flight: the primary shows a spinner and
  /// both footer buttons ignore taps, so a double tap can't skip a step.
  final bool isBusy;

  /// Floats above the content, e.g. the Undo toast.
  final Widget? overlay;

  @override
  Widget build(BuildContext context) {
    final primaryEnabled = onPrimary != null && !isBusy;
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: OnboardingProgressHeader(
                    step: step,
                    onBack: isBusy ? null : onBack,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: AppTextStyles.heading.copyWith(
                          fontSize: 28,
                          height: 1.15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      DefaultTextStyle.merge(
                        style: AppTextStyles.bodyMuted.copyWith(
                          fontSize: 15,
                          height: 1.45,
                        ),
                        child: subtitle,
                      ),
                    ],
                  ),
                ),
                Expanded(child: child),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
                  child: Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: primaryEnabled ? onPrimary : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.accent,
                            foregroundColor: AppColors.accentForeground,
                            disabledBackgroundColor: isBusy
                                ? AppColors.accent
                                : AppColors.secondaryFill,
                            disabledForegroundColor: isBusy
                                ? AppColors.accentForeground
                                : AppColors.mutedForeground,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: isBusy
                              ? const AppProgressIndicator(
                                  color: AppColors.accentForeground,
                                  radius: 9,
                                )
                              : Text(
                                  primaryLabel,
                                  style: AppTextStyles.buttonLabel.copyWith(
                                    color: primaryEnabled
                                        ? AppColors.accentForeground
                                        : AppColors.mutedForeground,
                                  ),
                                ),
                        ),
                      ),
                      SizedBox(
                        height: 44,
                        width: double.infinity,
                        child: secondaryLabel == null
                            ? null
                            : TextButton(
                                onPressed: isBusy ? null : onSecondary,
                                style: TextButton.styleFrom(
                                  foregroundColor: AppColors.accent,
                                ),
                                child: Text(
                                  secondaryLabel!,
                                  style: AppTextStyles.buttonLabelSecondary
                                      .copyWith(color: AppColors.accent),
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (overlay != null) overlay!,
          ],
        ),
      ),
    );
  }
}
