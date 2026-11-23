import 'package:kaunti47_v2/src/features/trip_plans/data/trip_plans_repository.dart';
import 'package:kaunti47_v2/src/features/trip_plans/domain/custom_place_draft.dart';
import 'package:kaunti47_v2/src/features/trip_plans/domain/new_plan_request.dart';
import 'package:kaunti47_v2/src/features/trip_plans/domain/plan_day_recording.dart';
import 'package:kaunti47_v2/src/features/trip_plans/domain/plan_failure.dart';
import 'package:kaunti47_v2/src/features/trip_plans/domain/plan_limits.dart';
import 'package:kaunti47_v2/src/features/trip_plans/domain/plan_member.dart';
import 'package:kaunti47_v2/src/features/trip_plans/domain/plan_ref.dart';
import 'package:kaunti47_v2/src/features/trip_plans/domain/trip_plan.dart';
import 'package:kaunti47_v2/src/features/trip_plans/domain/trip_plan_summary.dart';

/// An in-memory [TripPlansRepository] for tests. Set [failWith] to make
/// every call fail, as the server or the network would.
class FakeTripPlansRepository implements TripPlansRepository {
  FakeTripPlansRepository({
    List<TripPlanSummary>? plans,
    this.limits = PlanLimits.free,
  }) : plans = plans ?? [];

  List<TripPlanSummary> plans;
  PlanLimits limits;
  PlanFailureKind? failWith;
  final created = <NewPlanRequest>[];

  /// Plans [get] returns, by id.
  final detail = <String, TripPlan>{};
  final savedRoutes = <String>[];
  final moves = <String>[];
  final removed = <String>[];
  final orders = <String>[];
  int addedDays = 0;
  int conversions = 0;
  int listCalls = 0;
  int getCalls = 0;

  void _maybeFail() {
    final kind = failWith;
    if (kind != null) throw PlanFailure(kind);
  }

  @override
  Future<List<TripPlanSummary>> list() async {
    listCalls++;
    _maybeFail();
    return plans;
  }

  @override
  Future<PlanLimits> myLimits() async {
    _maybeFail();
    return limits;
  }

  @override
  Future<String> create(NewPlanRequest request) async {
    _maybeFail();
    created.add(request);
    final id = 'plan-${created.length}';
    plans = [
      ...plans,
      TripPlanSummary(
        id: id,
        title: request.title,
        ownerId: 'me',
        role: PlanRole.owner,
        startDate: request.startDate,
      ),
    ];
    return id;
  }

  /// Plans [plansWithPlace] reports, by place id.
  final holding = <String, List<PlanRef>>{};
  final added = <String>[];
  final recordings = <String, List<PlanDayRecording>>{};
  final links = <String>[];

  @override
  Future<List<PlanDayRecording>> myRecordings(String planId) async {
    _maybeFail();
    return recordings[planId] ?? const [];
  }

  @override
  Future<void> linkDayRecording(String dayId, String journeyId) async {
    _maybeFail();
    links.add('$dayId|$journeyId');
  }

  @override
  Future<List<PlanRef>> plansWithPlace(String placeId) async {
    _maybeFail();
    return holding[placeId] ?? const [];
  }

  @override
  Future<int> convertSavedTrips() async {
    conversions++;
    return 0;
  }

  @override
  Future<TripPlan> get(String planId) async {
    getCalls++;
    _maybeFail();
    final found = detail[planId];
    if (found == null) throw const PlanFailure(PlanFailureKind.notFound);
    return found;
  }

  @override
  Future<void> rename(String planId, String title) async => _maybeFail();
  @override
  Future<void> setStartDate(String planId, DateTime? date) async =>
      _maybeFail();
  @override
  Future<void> archive(String planId, {required bool archived}) async =>
      _maybeFail();
  @override
  Future<void> delete(String planId) async => _maybeFail();
  @override
  Future<String> addDay(String planId, {String? afterDayId}) async {
    _maybeFail();
    addedDays++;
    return 'day';
  }

  @override
  Future<void> removeDay(String dayId) async => _maybeFail();
  @override
  Future<void> renameDay(String dayId, String? title) async => _maybeFail();
  @override
  Future<String> addStop(
    String dayId,
    String placeId, {
    String? beforeStopId,
    String? note,
  }) async {
    _maybeFail();
    added.add('$dayId|$placeId');
    return 'stop-${added.length}';
  }

  @override
  Future<void> moveStop(
    String stopId,
    String dayId, {
    String? beforeStopId,
  }) async {
    _maybeFail();
    moves.add('$stopId|$dayId|$beforeStopId');
  }

  @override
  Future<void> removeStop(String stopId, {bool toPlacesList = false}) async {
    _maybeFail();
    removed.add('$stopId|$toPlacesList');
  }

  @override
  Future<void> setDayOrder(String dayId, List<String> stopIds) async {
    _maybeFail();
    orders.add('$dayId|${stopIds.join(',')}');
  }

  @override
  Future<void> setStopNote(String stopId, String? note) async => _maybeFail();
  @override
  Future<void> addPlace(String planId, String placeId, {String? note}) async {
    _maybeFail();
    added.add('list|$placeId');
  }

  @override
  Future<void> removePlace(String planId, String placeId) async => _maybeFail();
  @override
  Future<void> setStart(String planId, PlanStart start) async {
    _maybeFail();
    added.add('$planId|start:${start.kind.wire}');
  }

  @override
  Future<void> setOvernight(
    String dayId, {
    String? placeId,
    String? label,
    double? lat,
    double? lng,
  }) async {
    _maybeFail();
    added.add('$dayId|overnight:${placeId ?? label}');
  }

  @override
  Future<String> addCustomStop(
    String dayId,
    CustomPlaceDraft place, {
    String? beforeStopId,
  }) async {
    _maybeFail();
    added.add('$dayId|custom:${place.name}');
    return 'stop-${added.length}';
  }

  @override
  Future<void> addCustomPlace(String planId, CustomPlaceDraft place) async {
    _maybeFail();
    added.add('list|custom:${place.name}');
  }

  @override
  Future<void> removeCustomPlace(String planId, String customId) async =>
      _maybeFail();

  @override
  Future<void> addCustomIdeaToDay(String dayId, String customId) async {
    _maybeFail();
    added.add('$dayId|custom:$customId');
  }

  @override
  Future<void> saveDayRoute(
    String dayId, {
    required String stopsKey,
    required int distanceM,
    required int durationS,
    required List<int> countyCodes,
  }) async {
    _maybeFail();
    savedRoutes.add('$dayId|$stopsKey|$distanceM');
  }
}
