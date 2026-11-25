import 'package:flutter/material.dart';

import '../../design/app_colors.dart';
import '../../widgets/app_county_shape.dart';

/// The brand mark on share images (Trip and Passport): a small version of
/// the app's own icon - the gradient rounded-square holding the white Kenya
/// country outline ([AppCountryShape]) - plus the "Kaunti47" wordmark.
/// [inverted] swaps it to a white chip with the gradient's mid-blue shape,
/// for backgrounds that are already that brand gradient, where a white chip
/// reads and a second copy of the gradient wouldn't.
class AppShareWatermark extends StatelessWidget {
  const AppShareWatermark({
    super.key,
    required this.textStyle,
    this.inverted = false,
  });

  final TextStyle textStyle;
  final bool inverted;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 22,
        height: 22,
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: inverted ? Colors.white : null,
          gradient: inverted
              ? null
              : const LinearGradient(
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                  colors: [
                    AppColors.splashIconGradientStart,
                    AppColors.splashIconGradientMid,
                    AppColors.splashIconGradientEnd,
                  ],
                  stops: [0.04, 0.61, 0.94],
                ),
          borderRadius: BorderRadius.circular(6),
        ),
        child: AppCountryShape(
          fill: inverted ? AppColors.splashIconGradientMid : Colors.white,
        ),
      ),
      const SizedBox(width: 7),
      Text('Kaunti47', style: textStyle),
    ],
  );
}
