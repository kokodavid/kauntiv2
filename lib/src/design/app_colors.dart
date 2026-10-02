import 'package:flutter/material.dart';

class AppColors {
  const AppColors._();

  static const green = Color(0xFF23684A);
  static const ink = Color(0xFF22291F);
  static const accent = Color(0xFF0A84FF);
  static const accentForeground = Colors.white;
  static const mutedForeground = Color(0xFF71717A);
  static const secondaryFill = Color(0xFFEBEBEC);
  static const buttonForeground = Color(0xFF18181B);
  static const headingText = Color(0xFF404040);
  static const foreground = buttonForeground;
  static const kenyaPillBackground = Color(0xFF229EFF);
  static const iconButtonBackground = Color(0xFFE1E1E2);
  static const cardBorder = Color(0xFFE5E7EB);
  static const listDivider = Color(0xFFE5E7EB);
  static const pageBackground = Color(0xFFF5F5F5);
  static const lockedFill = Color(0xFFF1F5F9);
  static const lockedStroke = Color(0xFFCBD5E1);
  static const legendVisited = Color(0xFF0A84FF);
  // The Journey Replay map: the route ahead of the marker, a lighter
  // blue than the accent used for the part already played.
  static const routeUpcoming = Color(0xFFBBDDFF);
  static const legendPassed = Color(0xFFEAB308);
  static const pendingFill = Color(0xFFF59E0B);
  static const justUnlockedFill = Color(0xFFEF4444);
  static const legendHome = Color(0xFF22C55E);
  static const trackInactive = Color(0xFFE2E8F0);
  // Map Home county map (v1 parity): the newest badge's fill, and the dark
  // pill used by the map's county label and reset control.
  static const mapJustUnlocked = Color(0xFFC0342B);
  static const mapOverlayBackground = Color(0xF022291F);
  static const mapOverlayForeground = Color(0xFFF5F4EE);
  static const mapOverlayMuted = Color(0xFFC9C7BA);
  static const mapHighlightStroke = Color(0xFF22291F);
  // Real map "fog" over counties not yet claimed.
  static const mapFog = Color(0xFF5F6368);
  // Real map place pins, by place type.
  static const placePark = Color(0xFF2E7D32);
  static const placeMuseum = Color(0xFFA87B24);
  static const placeCulture = Color(0xFF7C3AED);
  static const placeHeritage = Color(0xFF8D5524);
  static const placeShore = Color(0xFF0891B2);
  static const placeOther = Color(0xFF475569);
  static const tabBarShell = Color(0xCCFFFFFF);
  static const tabPillBackground = Colors.white;
  static const permissionHeaderGradientEnd = Color(0xFF0A5FD4);
  static const heroSubheadingText = Color(0xFFCBD5E1);
  static const factTitleText = Color(0xFF0F172B);
  static const factBodyText = Color(0xFF45556C);
  static const noteBackground = Color(0xFFF8FAFC);
  static const noteMutedText = Color(0xFF62748E);
  static const noteStrongText = Color(0xFF314158);
  static const dangerSoftForeground = Color(0xFFA43532);
  static const danger = Color(0xFFFF383C);
  static const dangerForeground = accentForeground;
  static const splashBackground = Color(0xFFF5F5F5);
  static const splashIconGradientStart = Color(0xFFCAEFF9);
  static const splashIconGradientMid = Color(0xFF639FFD);
  static const splashIconGradientEnd = Color(0xFFB1ACFC);

  // County / Place Detail (v1 parity).
  static const factCardBorder = trackInactive;
  static const countyShapeCardBorder = lockedStroke;
  static const countyStatusChipBackground = Color(0x4D000000);
  static const backButtonBorder = Color(0xFFDADEEC);
  static const detailStatLabel = Color(0xFF94A3B8);
  static const detailStatValue = Color(0xFF475569);
  static const categoryHeritageDot = Color(0xFF7E22CE);
  static const categoryDotFallback = mutedForeground;
  static const detailGlassShadow = Color(0x1A000000);

  // Explore (v1 Discover parity).
  static const exploreSurface = Colors.white;
  static const exploreBorder = Color(0xFFEBEBEB);
  static const exploreText = Color(0xFF111111);
  static const exploreMutedText = Color(0xFF999999);
  static const exploreCategoryFill = Color(0xFFEEF4F1);
  static const exploreCategoryText = Color(0xFF2D5A3D);
  static const explorePromotionFill = Color(0xFFFFF2E4);
  static const explorePromotionText = Color(0xFFB45309);
  static const explorePhotoPlaceholder = Color(0xFFE8E8E8);

  // "..." actions menu popover (Claude-Design "Menu" reference).
  static const menuButtonPressed = Color(0xFFF1F1F2);
  static const menuItemPressed = Color(0xFFF5F5F5);
  static const menuDangerItemPressed = Color(0xFFFFF1F1);
  static const menuDivider = Color(0xFFF1F1F1);

  // Bottom-sheet dialogs (Claude-Design "03 - DIALOG" reference).
  static const sheetBarrier = Color(0x6609090B);
  static const dangerTint = Color(0xFFFFF1F1);

  // Floating toast (Claude-Design "01 - TOAST" reference).
  static const toastBackground = Color(0xFF18181B);
  static const toastSubtitle = Color(0xFFA1A1AA);
  static const toastActionBackground = Color(0x1AFFFFFF);
  static const toastSuccessIcon = Color(0xFF16A34A);
  static const toastWarningIcon = Color(0xFFF59E0B);
  static const toastNeutralIcon = Color(0xFF3F3F46);

  // Empty replay timeline (Claude-Design "Empty Timeline 2a/2b" reference).
  static const emptyTimelineCardBackground = Color(0xFFF4F6F8);
}
