import 'trip_plan.dart';

/// What a new plan starts from (the create sheet, design 2a to 2d).
class NewPlanRequest {
  const NewPlanRequest({
    required this.title,
    this.days = 1,
    this.startKind = PlanStartKind.currentLocation,
    this.startPlaceId,
    this.startLabel,
    this.startLat,
    this.startLng,
    this.startDate,
    this.firstPlaceId,
  });

  final String title;
  final int days;
  final PlanStartKind startKind;
  final String? startPlaceId;
  final String? startLabel;
  final double? startLat;
  final double? startLng;
  final DateTime? startDate;

  /// A place to put on Day 1 ("New plan with this place").
  final String? firstPlaceId;
}
