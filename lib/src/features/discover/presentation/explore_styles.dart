import 'package:flutter/material.dart';

import '../../../core/design/app_type_scale.dart';
import '../../../design/app_colors.dart';

/// Explore's card and row styles: the shared content scale
/// ([AppTypeScale]) in Explore's colours. Layout follows v1 Discover.
abstract final class ExploreStyles {
  static const _family = AppTypeScale.family;

  static final cardDecoration = BoxDecoration(
    color: AppColors.exploreSurface,
    border: Border.all(color: AppColors.exploreBorder),
    borderRadius: BorderRadius.circular(16),
  );

  static const countyTitle = TextStyle(
    fontFamily: _family,
    fontSize: AppTypeScale.cardTitleSize,
    fontWeight: FontWeight.w600,
    height: 24 / 16,
    color: AppColors.exploreText,
  );

  static const countyMeta = TextStyle(
    fontFamily: _family,
    fontSize: AppTypeScale.metaSize,
    height: 16.6 / 11,
    letterSpacing: AppTypeScale.metaTracking,
    color: AppColors.exploreMutedText,
  );

  static const placeCount = TextStyle(
    fontFamily: _family,
    fontSize: AppTypeScale.metaSize,
    color: AppColors.mutedForeground,
  );

  static const placeTitle = TextStyle(
    fontFamily: _family,
    fontSize: AppTypeScale.itemTitleSize,
    fontWeight: FontWeight.w500,
    height: 21 / 14,
    color: AppColors.exploreText,
  );

  static const placeBody = TextStyle(
    fontFamily: _family,
    fontSize: AppTypeScale.smallSize,
    height: 18 / 12,
    color: AppColors.exploreMutedText,
  );

  static const categoryChip = TextStyle(
    fontFamily: _family,
    fontSize: AppTypeScale.labelSize,
    fontWeight: FontWeight.w500,
    letterSpacing: AppTypeScale.labelTracking,
    color: AppColors.exploreCategoryText,
  );

  static const placeDistance = TextStyle(
    fontFamily: _family,
    fontSize: AppTypeScale.metaSize,
    color: AppColors.exploreMutedText,
  );

  static const link = TextStyle(
    fontFamily: _family,
    fontSize: AppTypeScale.labelSize,
    fontWeight: FontWeight.w600,
    letterSpacing: AppTypeScale.labelTracking,
    color: AppColors.exploreCategoryText,
  );

  static TextStyle tabChip({required bool selected}) => AppTypeScale.pill
      .copyWith(color: selected ? Colors.white : AppColors.exploreMutedText);

  static const emptyBody = AppTypeScale.body;

  static const insightTitle = TextStyle(
    fontFamily: _family,
    fontSize: AppTypeScale.itemTitleSize,
    fontWeight: FontWeight.w600,
    color: AppColors.exploreText,
  );

  /// SAVED's summary and footer lines.
  static const savedMeta = TextStyle(
    fontFamily: _family,
    fontSize: AppTypeScale.metaSize,
    height: 1.5,
    color: AppColors.mutedForeground,
  );

  static const completeLabel = TextStyle(
    fontFamily: _family,
    fontSize: 8,
    fontWeight: FontWeight.w600,
    letterSpacing: .4,
    color: AppColors.green,
  );

  static TextStyle wishlistTitle({required bool seen}) => TextStyle(
    fontFamily: _family,
    fontSize: AppTypeScale.bodySize,
    fontWeight: FontWeight.w600,
    color: seen ? AppColors.mutedForeground : AppColors.exploreText,
    decoration: seen ? TextDecoration.lineThrough : TextDecoration.none,
  );
}
