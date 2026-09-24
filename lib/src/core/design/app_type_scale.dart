import 'package:flutter/painting.dart';

import '../../design/app_colors.dart';

/// The shared content type scale (Inter) for cards, lists and detail
/// pages: Explore, County / Place Detail and Home's For You.
///
/// v1 set these screens in DM Sans; the same sizes read ~10% larger in
/// Inter, so the scale is tuned down (county names 16, not 18). Use the
/// styles directly, or build a const style from the size and tracking
/// constants when a screen needs its own colour.
abstract final class AppTypeScale {
  static const family = 'Inter';

  // Sizes.
  static const sectionTitleSize = 18.0;
  static const photoTitleSize = 18.0;
  static const cardTitleSize = 16.0;
  static const itemTitleSize = 14.0;
  static const bodySize = 13.0;
  static const actionSize = 13.0;
  static const statValueSize = 13.0;
  static const smallSize = 12.0;
  static const pillSize = 11.5;
  static const metaSize = 11.0;
  static const labelSize = 10.0;

  // Letter spacing for uppercase text.
  static const metaTracking = 0.3;
  static const pillTracking = 0.3;
  static const labelTracking = 0.5;

  /// Section headings on a page ("Places to See").
  static const sectionTitle = TextStyle(
    fontFamily: family,
    fontSize: sectionTitleSize,
    fontWeight: FontWeight.w600,
    height: 26 / 18,
    color: AppColors.foreground,
  );

  /// Small uppercase section labels ("FOR YOU - YOUR NEXT BEST MOVE").
  static const sectionLabel = TextStyle(
    fontFamily: family,
    fontSize: labelSize,
    fontWeight: FontWeight.w600,
    letterSpacing: labelTracking,
    color: AppColors.mutedForeground,
  );

  /// Card and list headings (county names).
  static const cardTitle = TextStyle(
    fontFamily: family,
    fontSize: cardTitleSize,
    fontWeight: FontWeight.w600,
    height: 24 / 16,
    color: AppColors.foreground,
  );

  /// Row titles inside a card (place names).
  static const itemTitle = TextStyle(
    fontFamily: family,
    fontSize: itemTitleSize,
    fontWeight: FontWeight.w500,
    height: 21 / 14,
    color: AppColors.foreground,
  );

  /// Running text: blurbs, descriptions, reasons.
  static const body = TextStyle(
    fontFamily: family,
    fontSize: bodySize,
    height: 20 / 13,
    color: AppColors.mutedForeground,
  );

  /// One-line summaries under a row title.
  static const small = TextStyle(
    fontFamily: family,
    fontSize: smallSize,
    height: 18 / 12,
    color: AppColors.mutedForeground,
  );

  /// Uppercase status lines ("EXPLORED", "RARITY NOT TRACKED YET").
  static const meta = TextStyle(
    fontFamily: family,
    fontSize: metaSize,
    height: 16.6 / 11,
    letterSpacing: metaTracking,
    color: AppColors.mutedForeground,
  );

  /// Filter and tab pills (unselected colour; swap for selected).
  static const pill = TextStyle(
    fontFamily: family,
    fontSize: pillSize,
    fontWeight: FontWeight.w500,
    height: 18 / 11.5,
    letterSpacing: pillTracking,
    color: AppColors.mutedForeground,
  );

  /// Inline actions ("Route ›").
  static const action = TextStyle(
    fontFamily: family,
    fontSize: actionSize,
    fontWeight: FontWeight.w500,
    height: 18 / 13,
    color: AppColors.accent,
  );

  /// A stat's value ("1,205 KM²") over its [statLabel].
  static const statValue = TextStyle(
    fontFamily: family,
    fontSize: statValueSize,
    fontWeight: FontWeight.w600,
    height: 22 / 13,
    color: AppColors.detailStatValue,
  );

  static const statLabel = TextStyle(
    fontFamily: family,
    fontSize: labelSize,
    height: 20 / 10,
    color: AppColors.detailStatLabel,
  );

  /// Titles set over a photo.
  static const photoTitle = TextStyle(
    fontFamily: family,
    fontSize: photoTitleSize,
    fontWeight: FontWeight.w600,
    height: 24 / 18,
    color: Color(0xFFFFFFFF),
  );

  /// Captions over a photo (location, distance, reason pills).
  static const photoCaption = TextStyle(
    fontFamily: family,
    fontSize: smallSize,
    height: 16 / 12,
    color: AppColors.heroSubheadingText,
  );
}
