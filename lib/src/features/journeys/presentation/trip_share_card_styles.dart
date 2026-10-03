part of 'trip_share_card.dart';

/// Text styles for both variants, sized from the Claude-Design reference
/// ("Inter throughout. Numbers are 700, units 500 at 75% white, labels
/// 600 caps with +0.07em tracking, county names 500 at 80% white. The
/// county count is the only display-size element."). Kept local to this
/// file rather than added to [AppTypeScale]: these sizes are specific to
/// this one card, not the shared content scale.
abstract final class _Styles {
  static const _white80 = Color(0xCCFFFFFF); // 80% white
  static const _white75 = Color(0xBFFFFFFF); // 75% white
  static const _white70 = Color(0xB3FFFFFF); // 70% white

  // Thumbnail.
  static const thumbChipText = TextStyle(
    fontFamily: AppTypeScale.family,
    fontSize: 12.5,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  );
  static const thumbWatermarkText = TextStyle(
    fontFamily: AppTypeScale.family,
    fontSize: 13.5,
    fontWeight: FontWeight.w700,
    color: Colors.white,
  );
  static const thumbCountyCount = TextStyle(
    fontFamily: AppTypeScale.family,
    fontSize: 34,
    fontWeight: FontWeight.w800,
    color: Colors.white,
    height: 1,
  );
  static const thumbCountyLabel = TextStyle(
    fontFamily: AppTypeScale.family,
    fontSize: 17,
    fontWeight: FontWeight.w700,
    color: Colors.white,
  );
  static const thumbCountyNames = TextStyle(
    fontFamily: AppTypeScale.family,
    fontSize: 12.5,
    fontWeight: FontWeight.w500,
    color: _white80,
  );
  static const thumbCountyMore = TextStyle(
    fontFamily: AppTypeScale.family,
    fontSize: 12.5,
    fontWeight: FontWeight.w700,
    color: Colors.white,
  );
  static const thumbStatValue = TextStyle(
    fontFamily: AppTypeScale.family,
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: Colors.white,
    height: 1,
  );
  static const thumbStatUnit = TextStyle(
    fontFamily: AppTypeScale.family,
    fontSize: 11.5,
    fontWeight: FontWeight.w500,
    color: _white75,
  );
  static const thumbStatLabel = TextStyle(
    fontFamily: AppTypeScale.family,
    fontSize: 9,
    fontWeight: FontWeight.w600,
    color: _white70,
    letterSpacing: 0.5,
  );

  // Share (4:5 / 9:16).
  static const shareChipText = TextStyle(
    fontFamily: AppTypeScale.family,
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  );
  static const shareWatermarkText = TextStyle(
    fontFamily: AppTypeScale.family,
    fontSize: 15,
    fontWeight: FontWeight.w700,
    color: Colors.white,
  );
  static const shareTitle = TextStyle(
    fontFamily: AppTypeScale.family,
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: _white80,
  );
  static const shareCountyCount = TextStyle(
    fontFamily: AppTypeScale.family,
    fontSize: 40,
    fontWeight: FontWeight.w800,
    color: Colors.white,
    height: 1,
  );
  static const shareCountyLabel = TextStyle(
    fontFamily: AppTypeScale.family,
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: Colors.white,
  );
  static const shareCountyNames = TextStyle(
    fontFamily: AppTypeScale.family,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: _white80,
  );
  static const shareCountyMore = TextStyle(
    fontFamily: AppTypeScale.family,
    fontSize: 14,
    fontWeight: FontWeight.w700,
    color: Colors.white,
  );
  static const shareStatValue = TextStyle(
    fontFamily: AppTypeScale.family,
    fontSize: 23,
    fontWeight: FontWeight.w700,
    color: Colors.white,
    height: 1,
  );
  static const shareStatUnit = TextStyle(
    fontFamily: AppTypeScale.family,
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: _white75,
  );
  static const shareStatLabel = TextStyle(
    fontFamily: AppTypeScale.family,
    fontSize: 10.5,
    fontWeight: FontWeight.w600,
    color: _white70,
    letterSpacing: 0.6,
  );
}
