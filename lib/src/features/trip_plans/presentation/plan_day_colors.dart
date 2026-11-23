import 'package:flutter/painting.dart';

import '../../../design/app_colors.dart';

/// Each day's route colour (planDay1 to planDay7); Day 8 loops back to
/// planDay1, and the day number on each pin keeps days apart.
abstract final class PlanDayColors {
  static const _colors = [
    AppColors.planDay1,
    AppColors.planDay2,
    AppColors.planDay3,
    AppColors.planDay4,
    AppColors.planDay5,
    AppColors.planDay6,
    AppColors.planDay7,
  ];

  /// The colour for day [number] (1-based).
  static Color of(int number) => _colors[(number - 1) % _colors.length];
}
