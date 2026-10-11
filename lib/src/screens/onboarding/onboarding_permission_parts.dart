import 'package:flutter/material.dart';

import '../../design/app_colors.dart';
import '../../design/app_text_styles.dart';

/// One reassurance row on setup step 3: an icon in a tinted square, a
/// bold lead-in and a short body.
class PermissionFact extends StatelessWidget {
  const PermissionFact({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
    this.tint = AppColors.accent,
  });

  final IconData icon;
  final String title;
  final String body;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: tint.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 18, color: tint),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text.rich(
              TextSpan(
                text: title,
                style: AppTextStyles.factBody.copyWith(
                  color: AppColors.factTitleText,
                  fontWeight: FontWeight.w600,
                  fontSize: 13.5,
                ),
                children: [
                  TextSpan(
                    text: ' $body',
                    style: AppTextStyles.factBody.copyWith(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// "Your phone asks next. Choose Allow all the time."
class PermissionPromptNote extends StatelessWidget {
  const PermissionPromptNote({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.noteBackground,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text.rich(
        TextSpan(
          style: AppTextStyles.noteText.copyWith(fontSize: 12.5),
          children: const [
            TextSpan(text: 'Your phone asks next. Choose '),
            TextSpan(
              text: 'Allow all the time',
              style: TextStyle(
                color: AppColors.noteStrongText,
                fontWeight: FontWeight.w600,
              ),
            ),
            TextSpan(text: '.'),
          ],
        ),
      ),
    );
  }
}

/// The three taps to turn location on once the phone won't ask again.
class PermissionSettingsSteps extends StatelessWidget {
  const PermissionSettingsSteps({super.key});

  static const _steps = [
    ('Tap ', 'Open Settings', ''),
    ('Choose ', 'Location', ''),
    ('Pick ', 'Always', ''),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.cardBorder),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          for (var i = 0; i < _steps.length; i++) ...[
            if (i > 0) const Divider(height: 1, color: AppColors.listDivider),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${i + 1}',
                      style: AppTextStyles.chipLabel.copyWith(
                        color: AppColors.accent,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text.rich(
                    TextSpan(
                      text: _steps[i].$1,
                      style: AppTextStyles.listItemTitle.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                      children: [
                        TextSpan(
                          text: _steps[i].$2,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// The dark "Skipped. Add interests anytime in Settings." toast with Undo,
/// shown on step 3 for a few seconds after skipping step 2.
class OnboardingUndoToast extends StatelessWidget {
  const OnboardingUndoToast({
    super.key,
    required this.message,
    required this.onUndo,
  });

  final String message;
  final VoidCallback onUndo;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.foreground,
      borderRadius: BorderRadius.circular(16),
      elevation: 6,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 4, 4, 4),
        child: Row(
          children: [
            Expanded(
              child: Text(
                message,
                style: AppTextStyles.toastMessage.copyWith(
                  color: Colors.white,
                  fontSize: 13.5,
                ),
              ),
            ),
            TextButton(
              onPressed: onUndo,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.accent,
                minimumSize: const Size(56, 44),
              ),
              child: Text(
                'Undo',
                style: AppTextStyles.buttonLabelSecondary.copyWith(
                  color: AppColors.accent,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
