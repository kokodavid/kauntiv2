import 'package:flutter/material.dart';

import '../../../design/app_colors.dart';
import '../../../widgets/app_icon_badge.dart';
import '../../../widgets/app_progress_indicator.dart';

/// The app icon mark. [halo] runs 0 (none) to 1 (full rings), so the forced
/// screen can grow the halo while the icon settles into place.
class UpdateAppIcon extends StatelessWidget {
  const UpdateAppIcon({super.key, this.size = 52, this.halo = 0});

  final double size;
  final double halo;

  @override
  Widget build(BuildContext context) {
    final icon = Semantics(
      label: 'Kaunti47',
      image: true,
      child: AppIconBadge(size: size),
    );
    if (halo <= 0) return icon;
    final r = size * 0.3;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(r + 34 * halo),
        color: AppColors.accent.withValues(alpha: 0.06 * halo),
      ),
      child: Padding(
        padding: EdgeInsets.all(24 * halo),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(r + 10 * halo),
            color: AppColors.infoTint.withValues(alpha: halo),
            boxShadow: [
              BoxShadow(
                color: AppColors.accentDark.withValues(alpha: 0.18 * halo),
                blurRadius: 30,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: Padding(padding: EdgeInsets.all(10 * halo), child: icon),
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
