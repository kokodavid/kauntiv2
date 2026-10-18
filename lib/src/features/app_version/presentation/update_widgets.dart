import 'package:flutter/material.dart';

import '../../../design/app_colors.dart';
import '../../../widgets/app_progress_indicator.dart';

/// The real launcher icon, optionally with the soft blue halo rings.
class UpdateAppIcon extends StatelessWidget {
  const UpdateAppIcon({super.key, this.size = 52, this.halo = false});

  final double size;
  final bool halo;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(size * 0.273);
    final icon = ClipRRect(
      borderRadius: radius,
      child: Image.asset(
        'assets/images/kaunti47_icon.png',
        width: size,
        height: size,
        semanticLabel: 'Kaunti47',
      ),
    );
    if (!halo) return icon;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.273 + 34),
        color: AppColors.accent.withValues(alpha: 0.06),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(size * 0.273 + 10),
            color: AppColors.infoTint,
            boxShadow: [
              BoxShadow(
                color: AppColors.accentDark.withValues(alpha: 0.18),
                blurRadius: 30,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: Padding(padding: const EdgeInsets.all(10), child: icon),
        ),
      ),
    );
  }
}

enum UpdateMessageTone { info, warning }

/// Inline card above the footer button: "Almost ready", "You're offline".
class UpdateInlineMessage extends StatelessWidget {
  const UpdateInlineMessage({
    super.key,
    required this.tone,
    required this.icon,
    required this.title,
    required this.body,
  });

  final UpdateMessageTone tone;
  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final warn = tone == UpdateMessageTone.warning;
    final text = warn ? AppColors.warningText : AppColors.accentDark;
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: warn ? AppColors.warningTint : AppColors.infoTint,
          border: Border.all(
            color: warn ? AppColors.warningBorder : AppColors.infoBorder,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              size: 20,
              color: warn ? AppColors.warningIcon : AppColors.accent,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: text,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    body,
                    style: TextStyle(fontSize: 13, height: 1.45, color: text),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum UpdateButtonStyle { filled, outlined, inactive }

/// Pill button for the update surfaces. [busy] swaps in the app's spinner and
/// keeps the width stable; the label stays readable at large text scales.
class UpdateButton extends StatelessWidget {
  const UpdateButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.style = UpdateButtonStyle.filled,
    this.busy = false,
    this.height = 56,
  });

  final String label;
  final VoidCallback? onPressed;
  final UpdateButtonStyle style;
  final bool busy;
  final double height;

  @override
  Widget build(BuildContext context) {
    final filled = style == UpdateButtonStyle.filled;
    final inactive = style == UpdateButtonStyle.inactive;
    final fg = filled
        ? Colors.white
        : inactive
        ? AppColors.bodyText
        : AppColors.foreground;
    final bg = filled
        ? AppColors.accent
        : inactive
        ? AppColors.softDivider
        : Colors.white;
    return Semantics(
      button: true,
      enabled: onPressed != null && !busy,
      child: Material(
        color: bg,
        shape: StadiumBorder(
          side: style == UpdateButtonStyle.outlined
              ? const BorderSide(color: AppColors.cardBorder)
              : BorderSide.none,
        ),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: busy ? null : onPressed,
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: height),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (busy) ...[
                    AppProgressIndicator(
                      radius: 9,
                      color: filled ? Colors.white : AppColors.accent,
                    ),
                    const SizedBox(width: 10),
                  ],
                  Flexible(
                    child: Text(
                      label,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: fg,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
