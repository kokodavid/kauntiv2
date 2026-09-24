import 'package:flutter/material.dart';

import 'app_colors.dart';

abstract final class AppTextStyles {
  static const _inter = 'Inter';

  static const buttonLabelSecondary = TextStyle(
    fontFamily: _inter,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 20 / 14,
    color: AppColors.buttonForeground,
  );

  static const bodySmall = TextStyle(
    fontFamily: _inter,
    fontSize: 11.5,
    fontWeight: FontWeight.w500,
    height: 1.45,
    color: AppColors.mutedForeground,
  );

  static const kickerText = TextStyle(
    fontFamily: _inter,
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 28 / 20,
    color: AppColors.mutedForeground,
  );

  static const heading = TextStyle(
    fontFamily: _inter,
    fontSize: 24,
    fontWeight: FontWeight.w600,
    height: 32 / 24,
    color: AppColors.headingText,
  );

  static const headingForeground = TextStyle(
    fontFamily: _inter,
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 28 / 20,
    color: AppColors.foreground,
  );

  static const bodyMuted = TextStyle(
    fontFamily: _inter,
    fontSize: 16,
    fontWeight: FontWeight.w500,
    height: 28 / 16,
    color: AppColors.mutedForeground,
  );

  static const buttonLabel = TextStyle(
    fontFamily: _inter,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 20 / 14,
    color: AppColors.accentForeground,
  );

  static const chipLabel = TextStyle(
    fontFamily: _inter,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 20 / 12,
    color: AppColors.foreground,
  );

  static const listItemTitle = TextStyle(
    fontFamily: _inter,
    fontSize: 16,
    fontWeight: FontWeight.w500,
    height: 28 / 16,
    color: AppColors.foreground,
  );

  static const listItemSubtitle = TextStyle(
    fontFamily: _inter,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 24 / 14,
    color: AppColors.mutedForeground,
  );

  static const searchInputText = TextStyle(
    fontFamily: _inter,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 20 / 14,
    color: AppColors.foreground,
  );

  static const heroHeading = TextStyle(
    fontFamily: _inter,
    fontSize: 24,
    fontWeight: FontWeight.w600,
    height: 32 / 24,
    color: Colors.white,
  );

  static const factBody = TextStyle(
    fontFamily: _inter,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 24 / 14,
    color: AppColors.factBodyText,
  );

  static const noteText = TextStyle(
    fontFamily: _inter,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 20 / 14,
    color: AppColors.noteMutedText,
  );

  static const toastTitle = TextStyle(
    fontFamily: _inter,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 24 / 14,
  );

  static const toastMessage = TextStyle(
    fontFamily: _inter,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 24 / 14,
    color: AppColors.mutedForeground,
  );

  static const tabBarLabelActive = TextStyle(
    fontFamily: _inter,
    fontSize: 10,
    fontWeight: FontWeight.w600,
    height: 12 / 10,
    color: AppColors.accent,
  );

  static const tabBarLabelInactive = TextStyle(
    fontFamily: _inter,
    fontSize: 10,
    fontWeight: FontWeight.w500,
    height: 12 / 10,
    color: AppColors.mutedForeground,
  );

  static const statNumeralCard = TextStyle(
    fontFamily: _inter,
    fontSize: 34,
    fontWeight: FontWeight.w300,
    color: AppColors.accent,
  );

  static const statNumeralCompact = TextStyle(
    fontFamily: _inter,
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.accent,
  );

  static const mapOverlayTitle = TextStyle(
    fontFamily: _inter,
    fontSize: 11,
    fontWeight: FontWeight.w600,
    color: AppColors.mapOverlayForeground,
  );

  static const mapOverlayMeta = TextStyle(
    fontFamily: _inter,
    fontSize: 7.5,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.4,
    color: AppColors.mapOverlayMuted,
  );

  static const mapOverlayChip = TextStyle(
    fontFamily: _inter,
    fontSize: 8.5,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.45,
    color: AppColors.mapOverlayForeground,
  );

  static const mapCountyLabel = TextStyle(
    fontFamily: _inter,
    fontSize: 11,
    fontWeight: FontWeight.w600,
    color: AppColors.mapOverlayForeground,
  );

  // County / Place Detail (v1 parity).
  static const detailTitle = TextStyle(
    fontFamily: _inter,
    fontSize: 24,
    fontWeight: FontWeight.w600,
    height: 32 / 24,
    color: AppColors.foreground,
  );

  static const detailNavTitle = TextStyle(
    fontFamily: _inter,
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 28 / 20,
    color: AppColors.foreground,
  );

  static const detailStatusChip = TextStyle(
    fontFamily: _inter,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 20 / 12,
    color: Colors.white,
  );

  static const detailStatLabel = TextStyle(
    fontFamily: _inter,
    fontSize: 10,
    fontWeight: FontWeight.w400,
    height: 20 / 10,
    color: AppColors.detailStatLabel,
  );

  static const detailStatValue = TextStyle(
    fontFamily: _inter,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 24 / 14,
    color: AppColors.detailStatValue,
  );

  static const placeCardTitle = TextStyle(
    fontFamily: _inter,
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 28 / 20,
    color: AppColors.detailStatValue,
  );
}
