import 'package:flutter/material.dart';

import '../../../core/design/app_type_scale.dart';
import '../../../design/app_colors.dart';

part 'journey_replay_controls_parts.dart';

/// A message in place of the replay (deleted, offline, too few points).
class JourneyReplayMessage extends StatelessWidget {
  const JourneyReplayMessage({super.key, required this.text, this.onRetry});

  final String text;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(text, textAlign: TextAlign.center, style: AppTypeScale.body),
          if (onRetry != null)
            TextButton(onPressed: onRetry, child: const Text('Try again')),
        ],
      ),
    );
  }
}

/// A round white button floating in a corner of the full-screen map.
class JourneyMapButton extends StatelessWidget {
  const JourneyMapButton({
    super.key,
    required this.alignment,
    required this.onPressed,
    required this.tooltip,
    required this.icon,
  });

  final Alignment alignment;
  final VoidCallback onPressed;
  final String tooltip;
  final IconData icon;

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
            icon: Icon(icon),
          ),
        ),
      ),
    );
  }
}

/// The "Whole route" pill floating over the map once replay is active -
/// an icon-and-label button (unlike [JourneyMapButton]'s icon-only round
/// shape) so it reads as an action rather than a settings toggle.
class JourneyWholeRoutePill extends StatelessWidget {
  const JourneyWholeRoutePill({super.key, required this.onPressed});

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
                    Icon(
                      Icons.zoom_out_map,
                      size: 16,
                      color: AppColors.accent,
                    ),
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
