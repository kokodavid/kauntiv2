import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../design/app_colors.dart';
import '../../design/app_text_styles.dart';
import '../../widgets/app_progress_indicator.dart';
import 'onboarding_progress_header.dart';

/// One shell for the three new-user setup steps (setup design v2): a blue
/// header with progress, an optional pill, the title and one line on what
/// the step powers; a white sheet with rounded top corners holding the
/// step's content; and a footer with the primary button and a reserved
/// secondary slot. The slot keeps its height when empty, so Continue sits
/// in the same place on every step.
class OnboardingShell extends StatelessWidget {
  const OnboardingShell({
    super.key,
    required this.step,
    required this.title,
    required this.subtitle,
    required this.child,
    required this.primaryLabel,
    required this.onPrimary,
    this.pill,
    this.onBack,
    this.secondaryLabel,
    this.onSecondary,
    this.footerCaption,
    this.footerNote,
    this.isBusy = false,
    this.overlay,
  });

  /// 1 to 3.
  final int step;
  final String title;

  /// A short pill above the title, e.g. "Earn all 47 counties".
  final String? pill;

  /// Plain text, or a rich line when part of it needs emphasis. Drawn in
  /// white on the blue header.
  final Widget subtitle;
  final Widget child;
  final String primaryLabel;

  /// Null disables the primary button.
  final VoidCallback? onPrimary;
  final VoidCallback? onBack;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;

  /// Quiet text in the secondary slot when there is no secondary action.
  final String? footerCaption;

  /// A line above the primary button that explains it, e.g. what the OS
  /// prompt will ask.
  final Widget? footerNote;

  /// True while a request is in flight: the primary shows a spinner and
  /// both footer buttons ignore taps, so a double tap can't skip a step.
  final bool isBusy;

  /// Floats above the sheet, e.g. the Undo toast.
  final Widget? overlay;

  @override
  Widget build(BuildContext context) {
    final primaryEnabled = onPrimary != null && !isBusy;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.accent,
        body: SafeArea(
          bottom: false,
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
                  _Heading(title: title, pill: pill, subtitle: subtitle),
                  Expanded(
                    child: DecoratedBox(
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(28),
                        ),
                      ),
                      child: Column(
                        children: [
                          Expanded(child: child),
                          _Footer(
                            primaryLabel: primaryLabel,
                            primaryEnabled: primaryEnabled,
                            isBusy: isBusy,
                            onPrimary: onPrimary,
                            secondaryLabel: secondaryLabel,
                            onSecondary: onSecondary,
                            footerCaption: footerCaption,
                            footerNote: footerNote,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              if (overlay != null) overlay!,
            ],
          ),
        ),
      ),
    );
  }
}

class _Heading extends StatelessWidget {
  const _Heading({
    required this.title,
    required this.pill,
    required this.subtitle,
  });

  final String title;
  final String? pill;
  final Widget subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 10, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (pill != null) ...[
            // A Row gives the pill unbounded width, so it hugs its text
            // instead of stretching across the header.
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  height: 26,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    pill!,
                    style: AppTextStyles.chipLabel.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
          Text(
            title,
            style: AppTextStyles.heading.copyWith(
              fontSize: 28,
              height: 1.15,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          DefaultTextStyle.merge(
            style: AppTextStyles.bodyMuted.copyWith(
              fontSize: 15,
              height: 1.45,
              color: Colors.white.withValues(alpha: 0.9),
            ),
            child: subtitle,
          ),
        ],
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({
    required this.primaryLabel,
    required this.primaryEnabled,
    required this.isBusy,
    required this.onPrimary,
    required this.secondaryLabel,
    required this.onSecondary,
    required this.footerCaption,
    required this.footerNote,
  });

  final String primaryLabel;
  final bool primaryEnabled;
  final bool isBusy;
  final VoidCallback? onPrimary;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;
  final String? footerCaption;
  final Widget? footerNote;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 10, 20, 16 + bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (footerNote != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: DefaultTextStyle.merge(
                style: AppTextStyles.bodySmall.copyWith(
                  fontSize: 12,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
                child: footerNote!,
              ),
            ),
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
            child: secondaryLabel != null
                ? TextButton(
                    onPressed: isBusy ? null : onSecondary,
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.accent,
                    ),
                    child: Text(
                      secondaryLabel!,
                      style: AppTextStyles.buttonLabelSecondary.copyWith(
                        color: AppColors.accent,
                      ),
                    ),
                  )
                : footerCaption == null
                ? null
                : Center(
                    child: Text(
                      footerCaption!,
                      style: AppTextStyles.bodySmall.copyWith(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
