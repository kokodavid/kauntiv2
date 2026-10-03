part of 'trip_share_sheet.dart';

abstract final class _Styles {
  static const stripHeading = TextStyle(
    fontFamily: AppTypeScale.family,
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: AppColors.mutedForeground,
  );
  static const stripCount = TextStyle(
    fontFamily: AppTypeScale.family,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.toastSubtitle,
  );
  static const shapeLabel = TextStyle(
    fontFamily: AppTypeScale.family,
    fontSize: 13,
    fontWeight: FontWeight.w600,
  );
  static const shapeRatio = TextStyle(
    fontFamily: AppTypeScale.family,
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: AppColors.toastSubtitle,
  );
  static const thumbTime = TextStyle(
    fontFamily: AppTypeScale.family,
    fontSize: 10.5,
    fontWeight: FontWeight.w500,
    color: AppColors.mutedForeground,
  );
  static const thumbTimeSelected = TextStyle(
    fontFamily: AppTypeScale.family,
    fontSize: 10.5,
    fontWeight: FontWeight.w600,
    color: AppColors.accent,
  );
}
