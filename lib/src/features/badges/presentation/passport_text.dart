import 'package:flutter/material.dart';

import '../../../core/design/app_type_scale.dart';

/// An Inter style for the Passport screens, with tabular numbers so counts
/// don't jiggle.
TextStyle passportText(
  double size, {
  FontWeight weight = FontWeight.w400,
  Color color = const Color(0xFF18181B),
  double? height,
  double letterSpacing = 0,
}) => TextStyle(
  fontFamily: AppTypeScale.family,
  fontSize: size,
  fontWeight: weight,
  color: color,
  height: height,
  letterSpacing: letterSpacing,
  fontFeatures: const [FontFeature.tabularFigures()],
);
