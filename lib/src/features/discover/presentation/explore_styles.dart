import 'package:flutter/material.dart';

import '../../../design/app_colors.dart';

/// Explore's card and row styles (v1 Discover parity, set in Inter like
/// the rest of v2).
abstract final class ExploreStyles {
  static const _inter = 'Inter';

  static final cardDecoration = BoxDecoration(
    color: AppColors.exploreSurface,
    border: Border.all(color: AppColors.exploreBorder),
    borderRadius: BorderRadius.circular(16),
  );

  static const sectionKicker = TextStyle(
    fontFamily: _inter,
    fontSize: 10,
    fontWeight: FontWeight.w500,
    letterSpacing: .5,
    color: AppColors.accent,
  );

  static const sectionTitle = TextStyle(
    fontFamily: _inter,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.exploreText,
  );

  static const countyTitle = TextStyle(
    fontFamily: _inter,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 27 / 18,
    color: AppColors.exploreText,
  );

  static const countyMeta = TextStyle(
    fontFamily: _inter,
    fontSize: 11,
    fontWeight: FontWeight.w400,
    height: 16.6 / 11,
    letterSpacing: .44,
    color: AppColors.exploreMutedText,
  );

  static const placeCount = TextStyle(
    fontFamily: _inter,
    fontSize: 11,
    color: AppColors.mutedForeground,
  );

  static const placeTitle = TextStyle(
    fontFamily: _inter,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 21 / 14,
    color: AppColors.exploreText,
  );

  static const placeBody = TextStyle(
    fontFamily: _inter,
    fontSize: 12,
    height: 18 / 12,
    color: AppColors.exploreMutedText,
  );

  static const categoryChip = TextStyle(
    fontFamily: _inter,
    fontSize: 10,
    fontWeight: FontWeight.w500,
    letterSpacing: .5,
    color: AppColors.exploreCategoryText,
  );

  static const placeDistance = TextStyle(
    fontFamily: _inter,
    fontSize: 11,
    color: AppColors.exploreMutedText,
  );

  static const unlockPill = TextStyle(
    fontFamily: _inter,
    fontSize: 10,
    fontWeight: FontWeight.w600,
    letterSpacing: .6,
    color: AppColors.exploreUnlockText,
  );

  static const link = TextStyle(
    fontFamily: _inter,
    fontSize: 10,
    fontWeight: FontWeight.w600,
    letterSpacing: .5,
    color: AppColors.exploreCategoryText,
  );

  static TextStyle tabChip({required bool selected}) => TextStyle(
    fontFamily: _inter,
    fontSize: 12.45,
    fontWeight: FontWeight.w500,
    height: 18.67 / 12.45,
    letterSpacing: .62,
    color: selected ? Colors.white : AppColors.exploreMutedText,
  );

  static const emptyBody = TextStyle(
    fontFamily: _inter,
    fontSize: 12.5,
    color: AppColors.mutedForeground,
  );

  static const photoTitle = TextStyle(
    fontFamily: _inter,
    fontSize: 22,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  );

  static const photoBlurb = TextStyle(
    fontFamily: _inter,
    fontSize: 13,
    height: 18 / 13,
    color: Colors.white,
  );

  static const insightTitle = TextStyle(
    fontFamily: _inter,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.exploreText,
  );

  /// SAVED's small uppercase summary and footer lines (v1 used a mono
  /// face; v2 has none, so Inter with tracking).
  static const savedMeta = TextStyle(
    fontFamily: _inter,
    fontSize: 9,
    letterSpacing: .4,
    height: 1.5,
    color: AppColors.mutedForeground,
  );

  static const completeLabel = TextStyle(
    fontFamily: _inter,
    fontSize: 8,
    fontWeight: FontWeight.w600,
    letterSpacing: .4,
    color: AppColors.green,
  );

  static TextStyle wishlistTitle({required bool seen}) => TextStyle(
    fontFamily: _inter,
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: seen ? AppColors.mutedForeground : AppColors.exploreText,
    decoration: seen ? TextDecoration.lineThrough : TextDecoration.none,
  );
}
