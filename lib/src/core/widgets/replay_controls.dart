import 'package:flutter/material.dart';

import '../../design/app_colors.dart';
import '../design/app_type_scale.dart';

/// A round white button floating in a corner of the full-screen map.
class ReplayMapButton extends StatelessWidget {
  const ReplayMapButton({
    super.key,
    required this.alignment,
    required this.onPressed,
    required this.tooltip,
    this.icon,
    this.iconWidget,
  }) : assert(
         icon != null || iconWidget != null,
         'ReplayMapButton needs either icon or iconWidget.',
       );

  final Alignment alignment;
  final VoidCallback onPressed;
  final String tooltip;

  /// A plain Material glyph - fine for a stock shape like [Icons.close].
  final IconData? icon;

  /// A custom-drawn glyph (see [AppGlyphIcon]) for an action whose stock
  /// Material icon doesn't match the Claude-Design reference closely
  /// enough - e.g. the share button's upload-arrow-and-tray icon.
  /// Overrides [icon] when both are set.
  final Widget? iconWidget;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Align(
        alignment: alignment,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: IconButton.filled(
            onPressed: onPressed,
            tooltip: tooltip,
            style: IconButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.foreground,
            ),
            icon: iconWidget ?? Icon(icon),
          ),
        ),
      ),
    );
  }
}

/// The "Whole route" pill floating over the map once replay is active -
/// an icon-and-label button (unlike [ReplayMapButton]'s icon-only round
/// shape) so it reads as an action rather than a settings toggle.
class ReplayWholeRoutePill extends StatelessWidget {
  const ReplayWholeRoutePill({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Align(
        alignment: Alignment.topRight,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(999),
            child: InkWell(
              borderRadius: BorderRadius.circular(999),
              onTap: onPressed,
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.zoom_out_map, size: 16, color: AppColors.accent),
                    SizedBox(width: 6),
                    Text(
                      'Whole route',
                      style: TextStyle(
                        fontFamily: AppTypeScale.family,
                        fontSize: AppTypeScale.actionSize,
                        fontWeight: FontWeight.w600,
                        color: AppColors.accent,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
