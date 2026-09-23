import 'package:flutter/material.dart';

import '../../../design/app_colors.dart';
import '../domain/map_home_models.dart';
import 'map_home_map_overlays.dart';
import 'pro_map_place_widgets.dart';

/// Top of the Pro map: back button and place legend on the left, the
/// selected county's label on the right.
class ProMapTopOverlay extends StatelessWidget {
  const ProMapTopOverlay({
    super.key,
    required this.showLegend,
    required this.selected,
  });

  final bool showLegend;
  final MapHomeCountyBadge? selected;

  @override
  Widget build(BuildContext context) {
    final selected = this.selected;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ProMapRoundButton(
                  icon: Icons.arrow_back,
                  onPressed: () => Navigator.of(context).pop(),
                ),
                if (showLegend) ...[
                  const SizedBox(height: 8),
                  const ProMapPlaceLegend(),
                ],
              ],
            ),
            const Spacer(),
            if (selected != null) MapHomeCountyLabel(badge: selected),
          ],
        ),
      ),
    );
  }
}

/// Dark round map button (back, locate me).
class ProMapRoundButton extends StatelessWidget {
  const ProMapRoundButton({
    super.key,
    required this.icon,
    required this.onPressed,
  });

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton.filled(
      onPressed: onPressed,
      style: IconButton.styleFrom(
        backgroundColor: AppColors.mapOverlayBackground,
      ),
      icon: Icon(icon, color: AppColors.mapOverlayForeground),
    );
  }
}
