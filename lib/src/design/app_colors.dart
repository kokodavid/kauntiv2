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
  // The Journey Replay map: the route ahead of the marker, line and
  // dots. Same accent blue as the part already played and the rest of
  // the map's colour key (start marker, playhead) - was a lighter
  // #BBDDFF, moved to accent so the whole route reads as one colour.
  static const routeUpcoming = accent;
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

  // Journey Replay map colour key (Claude-Design reference). Start/end
  // and the playhead reuse [accent]/[foreground] already above; these
  // two are the pale-amber "detected stop" pin (direction 2c) and its
  // amber outline - not yet drawn by the live route map (only the
  // empty-timeline illustration work that introduces detected-stop and
  // suggested-moment pins will need them), kept here so both land
  // together with the rest of that colour key.
  static const mapDetectedStopFill = Color(0xFFFEF3C7);
  static const mapDetectedStopOutline = Color(0xFFD97706);

  // Bottom sheets and text-form fields (Profile/Settings "Edit profile",
  // Membership, Data & privacy). Material 3's default surface tint and
  // input-decoration colors derive from the theme's seed color, which is
  // still the old brand green (`app.dart`) -- these are explicit so sheets
  // and fields never pick that up.
  static const sheetBackground = Colors.white;
  static const inputBorder = cardBorder;
  static const inputFocusedBorder = accent;

  // Trip planner: warning note (a much longer stop order) and the "new
  // county" tag.
  static const warningBackground = Color(0xFFFFF6E5);
  static const warningBorder = Color(0xFFFBE3B4);
  static const warningText = Color(0xFF7A4B00);
  static const newCountyText = Color(0xFF16A34A);
  static const accentPressed = Color(0xFF0066D6);
  static const accentTint = Color(0xFFEEF5FF);
  static const segmentedTrack = Color(0xFFE7E8EB);
  static const photoPlaceholder = Color(0xFF3A4150);
}
