import 'package:flutter/material.dart';

import '../../../design/app_colors.dart';

/// A 48 pt white round button floating over the full-screen map.
class TripMapRoundButton extends StatelessWidget {
  const TripMapRoundButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 3,
      child: SizedBox.square(
        dimension: 48,
        child: IconButton(
          tooltip: tooltip,
          icon: Icon(icon, size: 22, color: AppColors.foreground),
          onPressed: onPressed,
        ),
      ),
    );
  }
}
