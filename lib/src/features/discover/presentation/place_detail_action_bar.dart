import 'package:flutter/material.dart';

import '../../../core/widgets/app_bottom_nav.dart';
import '../../../design/app_colors.dart';

/// Place Detail's floating action bar: the page's primary actions in one
/// pill, floating `AppBottomNav.bottomGap` above the bottom edge in the
/// same shape, shadow and 24pt side margin as the app's own tab bar --
/// a compact pill centered on the screen, not a bar stretched edge to
/// edge. Route is the one item that is always highlighted; Add to trip,
/// the check-in button (when the place has coordinates) and Add photo
/// (when the place takes photos) sit beside it with equal weight.
/// Replaces the old full-width docked bottom bar (`PlaceDetailBar`).
class PlaceDetailActionBar extends StatelessWidget {
  const PlaceDetailActionBar({
    super.key,
    required this.addToTrip,
    required this.route,
    this.checkIn,
    this.addPhoto,
  });

  final Widget addToTrip;
  final Widget route;

  /// Null for a place with no coordinates: the bar then shows just
  /// Add to trip, (Add photo) and Route.
  final Widget? checkIn;

  /// Null while the place doesn't take photos or the feature is off.
  final Widget? addPhoto;

  // Capped close to AppBottomNav's own 300/360 so a 3 or 4 item bar
  // stays a compact pill, not a bar stretched edge to edge.
  static const _maxWidthByCount = {1: 140.0, 2: 210.0, 3: 290.0, 4: 360.0};

  @override
  Widget build(BuildContext context) {
    final count = 2 + (checkIn == null ? 0 : 1) + (addPhoto == null ? 0 : 1);
    return Positioned(
      left: 24,
      right: 24,
      bottom: AppBottomNav.bottomGap(context),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: _maxWidthByCount[count] ?? 360),
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.tabBarShell,
              borderRadius: BorderRadius.circular(999),
              boxShadow: const [
                BoxShadow(
                  color: AppColors.detailGlassShadow,
                  offset: Offset(0, 2),
                  blurRadius: 17,
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(child: addToTrip),
                if (checkIn != null) Expanded(child: checkIn!),
                if (addPhoto != null) Expanded(child: addPhoto!),
                Expanded(child: route),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
