import '../domain/new_plan_request.dart';
import '../domain/plan_day_recording.dart';
import '../domain/plan_limits.dart';
import '../domain/plan_ref.dart';
import '../domain/trip_plan.dart';
import '../domain/trip_plan_summary.dart';

/// The trip planner's server calls. Every change goes through a database
/// function that checks membership, role and the owner's limits; refusals
/// arrive as `PlanFailure`.
abstract interface class TripPlansRepository {
  Future<List<TripPlanSummary>> list();
  Future<TripPlan> get(String planId);
  Future<PlanLimits> myLimits();

  /// Returns the new plan's id.
  Future<String> create(NewPlanRequest request);
  Future<void> rename(String planId, String title);
  Future<void> setStartDate(String planId, DateTime? date);
  Future<void> archive(String planId, {required bool archived});
  Future<void> delete(String planId);

  /// Returns the new day's id.
  Future<String> addDay(String planId, {String? afterDayId});
  Future<void> removeDay(String dayId);
  Future<void> renameDay(String dayId, String? title);

  /// Returns the new stop's id.
  Future<String> addStop(
    String dayId,
    String placeId, {
    String? beforeStopId,
    String? note,
  });
  Future<void> moveStop(String stopId, String dayId, {String? beforeStopId});
  Future<void> removeStop(String stopId, {bool toPlacesList = false});
  /// Puts a day's stops in this order (all of them, once each). Refused
  /// (orderStale) when the day changed meanwhile.
  Future<void> setDayOrder(String dayId, List<String> stopIds);
  Future<void> setStopNote(String stopId, String? note);

  Future<void> addPlace(String planId, String placeId, {String? note});
  Future<void> removePlace(String planId, String placeId);

  /// Saves the route worked out for a day. Refused (routeStale) when the
  /// day changed meanwhile.
  Future<void> saveDayRoute(
    String dayId, {
    required String stopsKey,
    required int distanceM,
    required int durationS,
    required List<int> countyCodes,
  });

  /// My plans that already hold [placeId] (on a day or Places to visit).
  Future<List<PlanRef>> plansWithPlace(String placeId);

  /// The Trips I recorded for [planId]'s days (the latest per day).
  Future<List<PlanDayRecording>> myRecordings(String planId);

  /// Links the Trip being recorded to a plan day. Its id is made on the
  /// phone; the link counts once the Trip is uploaded.
  Future<void> linkDayRecording(String dayId, String journeyId);

  /// Moves the old planner's saved trips into plans; returns how many.
  Future<int> convertSavedTrips();
}
