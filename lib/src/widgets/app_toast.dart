import 'package:flutter/material.dart';

import '../design/app_colors.dart';
import '../design/app_text_styles.dart';

/// Tone for [AppToast]. Only [danger] exists in the Figma file so far
/// (the location-permission-disabled banner, node 235:6850) -- kept as
/// a switch rather than a single hardcoded color set because a banner
/// like this is exactly the kind of component other flows will want in
/// success/warning/info tones later, and nothing else about the layout
/// is tone-specific.
enum AppToastTone { danger }

/// Reusable toast/banner (Figma node 235:6904, "Toast" -- a HeroUI-
/// documented Code Connect component). Icon + title/message column +
/// an optional trailing pill action button, on a white card with a
/// soft multi-layer shadow. First used by [OnboardingPermissionPage]'s
/// permission-disabled state; built standalone here so any other screen
/// that needs a floating status banner (a denied-permission notice, a
/// sync failure, etc.) can reuse it instead of re-deriving one.
class AppToast extends StatelessWidget {
  const AppToast({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.tone = AppToastTone.danger,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final AppToastTone tone;

  /// When both are set, a trailing pill button is shown (e.g. "Open").
  final String? actionLabel;
  final VoidCallback? onAction;

  Color get _titleColor => switch (tone) {
    AppToastTone.danger => AppColors.dangerSoftForeground,
  };

  Color get _actionColor => switch (tone) {
    AppToastTone.danger => AppColors.danger,
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          // Figma's three stacked drop shadows (node 235:6904's
          // "shadow-overlay" effect) -- a soft ambient shadow plus a
          // slight upward highlight so the toast reads as floating
          // just above the header it's shown over.
          BoxShadow(
            color: Color(0x0F000000),
            offset: Offset(0, 2),
            blurRadius: 8,
          ),
          BoxShadow(
            color: Color(0x14000000),
            offset: Offset(0, 14),
            blurRadius: 28,
          ),
          BoxShadow(
            color: Color(0x08000000),
            offset: Offset(0, -6),
            blurRadius: 12,
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Icon(icon, size: 16, color: _titleColor),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.toastTitle.copyWith(
                      color: _titleColor,
                    ),
                  ),
                  Text(message, style: AppTextStyles.toastMessage),
                ],
              ),
            ),
          ),
          if (actionLabel != null) ...[
            const SizedBox(width: 8),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: SizedBox(
                height: 36,
                child: ElevatedButton(
                  onPressed: onAction,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _actionColor,
                    disabledBackgroundColor: _actionColor,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  child: Text(actionLabel!, style: AppTextStyles.buttonLabel),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
