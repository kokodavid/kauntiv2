import 'package:flutter/material.dart';

import '../../../design/app_colors.dart';
import '../domain/place_category.dart';

extension PlaceCategoryStyle on PlaceCategory {
  Color get dotColor => this == PlaceCategory.heritage
      ? AppColors.categoryHeritageDot
      : AppColors.categoryDotFallback;
}
