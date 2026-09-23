import 'package:flutter/material.dart';

import '../design/app_colors.dart';
import 'app_county_shape.dart';

/// The v2 app-icon mark: a rounded-square with a diagonal light-blue-to-
/// lavender gradient fill, holding the white Kenya country outline
/// (`AppCountryShape`). Used at 100px on the splash screen (node
/// 235:4722) and at 60px on Onboarding 02 (node 235:7212) -- factored out
/// here so both call sites stay in sync rather than duplicating the same
/// gradient/padding/radius decisions inline.
class AppIconBadge extends StatelessWidget {
  const AppIconBadge({super.key, this.size = 100});

  final double size;

  @override
  Widget build(BuildContext context) {
    // The Figma frames use a fixed corner radius (30px at 100px, 18px at
    // 60px) rather than a fixed fraction of size -- scale proportionally
    // from the 100px/30px reference so this still looks right at other
    // sizes.
    final radius = size * 0.3;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        // Figma specifies a 194.19deg CSS diagonal; topRight -> bottomLeft
        // is the closest Alignment-based approximation for a fill this
        // small, and exact angle fidelity doesn't read at icon scale.
        gradient: const LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            AppColors.splashIconGradientStart,
            AppColors.splashIconGradientMid,
            AppColors.splashIconGradientEnd,
          ],
          stops: [0.04, 0.61, 0.94],
        ),
      ),
      padding: EdgeInsets.all(size * 0.22),
      child: const AppCountryShape(fill: Colors.white),
    );
  }
}
