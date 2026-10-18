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

  static const placeBody = TextStyle(
    fontFamily: _family,
    fontSize: AppTypeScale.smallSize,
    height: 18 / 12,
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

  static const landingKicker = TextStyle(
    fontFamily: _family,
    fontSize: AppTypeScale.labelSize,
    fontWeight: FontWeight.w600,
    letterSpacing: .5,
    color: AppColors.exploreCategoryText,
  );

  static const landingHeadline = TextStyle(
    fontFamily: _family,
    fontSize: 24,
    height: 1.25,
    fontWeight: FontWeight.w600,
    color: AppColors.exploreText,
  );

  static const landingCardTitle = TextStyle(
    fontFamily: _family,
    fontSize: 20,
    height: 1.25,
    fontWeight: FontWeight.w600,
    color: AppColors.exploreText,
  );

  static const chapterTitle = TextStyle(
    fontFamily: _family,
    fontSize: 18,
    height: 1.3,
    fontWeight: FontWeight.w600,
    color: AppColors.exploreText,
  );

  static const fieldPlaceTitle = TextStyle(
    fontFamily: _family,
    fontSize: AppTypeScale.itemTitleSize,
    height: 21 / 14,
    fontWeight: FontWeight.w500,
    color: AppColors.exploreText,
  );

  static const fieldPlaceMeta = TextStyle(
    fontFamily: _family,
    fontSize: AppTypeScale.smallSize,
    height: 18 / 12,
    color: AppColors.exploreMutedText,
  );

  static const fieldPlaceBadge = TextStyle(
    fontFamily: _family,
    fontSize: 10,
    fontWeight: FontWeight.w600,
    letterSpacing: AppTypeScale.labelTracking,
    color: AppColors.exploreCategoryText,
  );

  static TextStyle fieldCardTitle({required bool onImage}) => TextStyle(
    fontFamily: _family,
    fontSize: 16,
    height: 1.2,
    fontWeight: FontWeight.w600,
    color: onImage ? Colors.white : AppColors.exploreText,
  );

  static TextStyle fieldCardMeta({required bool onImage}) => TextStyle(
    fontFamily: _family,
    fontSize: 12,
    color: onImage ? Colors.white70 : AppColors.mutedForeground,
  );

  static TextStyle fieldCardCounty({required bool onImage}) => TextStyle(
    fontFamily: _family,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: onImage ? Colors.white : AppColors.exploreText,
  );

  static TextStyle countyFieldTitle({required bool onImage}) => TextStyle(
    fontFamily: _family,
    fontSize: 16,
    height: 1.2,
    fontWeight: FontWeight.w600,
    color: onImage ? Colors.white : AppColors.exploreText,
  );

  static TextStyle countyFieldMeta({required bool onImage}) => TextStyle(
    fontFamily: _family,
    fontSize: 11,
    height: 1.25,
    letterSpacing: .3,
    color: onImage ? Colors.white70 : AppColors.mutedForeground,
  );

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

  // Field Guide v2 filter and band pieces.
  static const filterPillFill = AppColors.accentTint;
  static const filterPillText = AppColors.accentPressed;

  static const resultsSentence = TextStyle(
    fontFamily: _family,
    fontSize: 24,
    height: 1.25,
    letterSpacing: -0.24,
    fontWeight: FontWeight.w600,
    color: AppColors.exploreText,
  );

  static const bandLabel = TextStyle(
    fontFamily: _family,
    fontSize: AppTypeScale.labelSize,
    fontWeight: FontWeight.w600,
    letterSpacing: AppTypeScale.labelTracking,
    color: AppColors.mutedForeground,
  );

  static const bandCount = TextStyle(
    fontFamily: _family,
    fontSize: AppTypeScale.metaSize,
    fontWeight: FontWeight.w500,
    color: AppColors.mutedForeground,
  );

  static const rowTitle = TextStyle(
    fontFamily: _family,
    fontSize: AppTypeScale.itemTitleSize,
    fontWeight: FontWeight.w500,
    color: AppColors.exploreText,
  );

  static const rowMeta = TextStyle(
    fontFamily: _family,
    fontSize: AppTypeScale.smallSize,
    color: AppColors.mutedForeground,
  );

  static const rowCounty = TextStyle(
    fontFamily: _family,
    fontSize: AppTypeScale.smallSize,
    fontWeight: FontWeight.w500,
    color: AppColors.exploreText,
  );
}
