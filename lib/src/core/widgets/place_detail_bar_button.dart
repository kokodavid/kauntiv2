import 'package:flutter/material.dart';

import '../../design/app_colors.dart';
import '../../widgets/app_progress_indicator.dart';
import '../design/app_type_scale.dart';

/// One pill-bar button, sized, padded and spaced exactly like
/// `AppBottomNav`'s own tabs (its `_NavTabButton`'s 7/6 padding, 16
/// icon, 2 gap, size-10 label) so Place Detail's floating action bar
/// reads as the same control as the Home tab bar, not a bigger or
/// tighter one.
/// Used by Place Detail's floating action bar: [AddToTripBarItem],
/// [PlaceCheckInBarItem] (via the place_check_ins and trip_plans
/// features), [AddPhotoBarItem] and the Route button share this one
/// look instead of each drawing its own pill.
///
/// [highlighted] gives a button the bar's primary-action treatment (the
/// white-to-blue wash `AppBottomNav` uses for its selected tab) -- Route
/// is the one item that is always highlighted. [tone] overrides the
/// icon/label color for a quiet "done" state (a check-in that just
/// counted) without the full highlighted look.
class PlaceDetailBarButton extends StatelessWidget {
  const PlaceDetailBarButton({
    super.key,
    required this.icon,
    required this.label,
    this.onPressed,
    this.busy = false,
    this.highlighted = false,
    this.tone,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final bool busy;
  final bool highlighted;
  final Color? tone;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !busy;
    final color = highlighted
        ? AppColors.accent
        : tone ?? (enabled ? AppColors.foreground : AppColors.mutedForeground);
    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: enabled ? onPressed : null,
          child: Container(
            // Same 7/6 padding as AppBottomNav's own tabs, not a forced
            // height, so this sizes identically to them.
            padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 6),
            decoration: highlighted
                ? BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppColors.tabPillBackground,
                        AppColors.tabPillWashEnd,
                      ],
                    ),
                    border: Border.all(color: AppColors.tabPillEdge),
                    borderRadius: BorderRadius.circular(999),
                  )
                : null,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                busy
                    ? SizedBox.square(
                        dimension: 16,
                        child: AppProgressIndicator(color: color, radius: 7),
                      )
                    : Icon(icon, size: 16, color: color),
                const SizedBox(height: 2),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: AppTypeScale.family,
                    fontSize: 10,
                    height: 12 / 10,
                    fontWeight: highlighted ? FontWeight.w600 : FontWeight.w500,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
