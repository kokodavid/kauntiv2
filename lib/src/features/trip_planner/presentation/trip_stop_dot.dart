import 'package:flutter/material.dart';

import '../../../core/design/app_type_scale.dart';
import '../../../design/app_colors.dart';

/// The round marker of a stop in the lists: green for where the trip
/// starts, blue and numbered for a stop, red for the place itself. Matches
/// the pins on the map.
class TripStopDot extends StatelessWidget {
  const TripStopDot.start({super.key, this.size = 22})
    : color = AppColors.legendHome,
      label = null;

  const TripStopDot.stop(int number, {super.key, this.size = 22})
    : color = AppColors.accent,
      label = number;

  const TripStopDot.end({super.key, this.size = 22})
    : color = AppColors.danger,
      label = null;

  final Color color;
  final int? label;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: label == null
          ? null
          : Text(
              '$label',
              style: AppTypeScale.small.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: size * 0.5,
                height: 1,
              ),
            ),
    );
  }
}
