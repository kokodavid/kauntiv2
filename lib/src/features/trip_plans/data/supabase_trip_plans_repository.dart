import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/custom_place_draft.dart';
import '../domain/new_plan_request.dart';
import '../domain/plan_day_recording.dart';
import '../domain/plan_failure.dart';
import '../domain/plan_limits.dart';
import '../domain/plan_ref.dart';
import '../domain/trip_plan.dart';
import '../domain/trip_plan_summary.dart';
import 'plan_rpc.dart';
import 'trip_plans_repository.dart';

/// [TripPlansRepository] over the planner's database functions
/// (`supabase/migrations/20261101101000_trip_plans_rpcs.sql`).
class SupabaseTripPlansRepository implements TripPlansRepository {
  const SupabaseTripPlansRepository(this.client);

  final SupabaseClient client;

  Future<Object?> _call(String fn, [Map<String, Object?>? params]) =>
      callPlanRpc(client, fn, params);

  static String? _date(DateTime? date) => date == null
      ? null
      : '${date.year.toString().padLeft(4, '0')}-'
            '${date.month.toString().padLeft(2, '0')}-'
            '${date.day.toString().padLeft(2, '0')}';

  @override
  Future<List<TripPlanSummary>> list() async {
    final result = await _call('list_trip_plans');
    return [
      if (result is List)
        for (final raw in result) ?TripPlanSummary.fromJson(raw),
    ];
  }

  @override
  Future<TripPlan> get(String planId) async {
    final result = await _call('get_trip_plan', {'p_plan': planId});
    final plan = TripPlan.fromJson(result);
    if (plan == null) throw const PlanFailure(PlanFailureKind.notFound);
    return plan;
  }

  @override
  Future<List<PlanRef>> plansWithPlace(String placeId) async {
    final result = await _call('trip_plans_with_place', {'p_place': placeId});
    return [
      if (result is List)
        for (final raw in result) ?PlanRef.fromJson(raw),
    ];
  }

  @override
  Future<List<PlanDayRecording>> myRecordings(String planId) async {
    final result = await _call('my_trip_plan_recordings', {'p_plan': planId});
    return [
      if (result is List)
        for (final raw in result) ?PlanDayRecording.fromJson(raw),
    ];
  }

  @override
  Future<void> linkDayRecording(String dayId, String journeyId) => _call(
    'link_trip_plan_day_recording',
    {'p_day': dayId, 'p_journey': journeyId},
  );

  @override
  Future<PlanLimits> myLimits() async =>
      PlanLimits.fromJson(await _call('my_trip_plan_limits'));

  @override
  Future<String> create(NewPlanRequest request) async {
    final result = await _call('create_trip_plan', {
      'p_title': request.title,
      'p_days': request.days,
      'p_start_kind': request.startKind.wire,
      'p_start_place_id': request.startPlaceId,
      'p_start_label': request.startLabel,
      'p_start_lat': request.startLat,
      'p_start_lng': request.startLng,
      'p_start_date': _date(request.startDate),
      'p_first_place_id': request.firstPlaceId,
    });
    if (result is! String) throw const PlanFailure(PlanFailureKind.unknown);
    return result;
  }

  @override
  Future<void> rename(String planId, String title) =>
      _call('update_trip_plan', {'p_plan': planId, 'p_title': title});

  @override
  Future<void> setStartDate(String planId, DateTime? date) =>
      _call('update_trip_plan', {
        'p_plan': planId,
        'p_start_date': _date(date),
        'p_clear_start_date': date == null,
      });

  @override
  Future<void> archive(String planId, {required bool archived}) =>
      _call('archive_trip_plan', {'p_plan': planId, 'p_archived': archived});

  @override
  Future<void> delete(String planId) =>
      _call('delete_trip_plan', {'p_plan': planId});

  @override
  Future<String> addDay(String planId, {String? afterDayId}) async {
    final result = await _call('add_trip_plan_day', {
      'p_plan': planId,
      'p_after_day': afterDayId,
    });
    if (result is! String) throw const PlanFailure(PlanFailureKind.unknown);
    return result;
  }

  @override
  Future<void> removeDay(String dayId) =>
      _call('remove_trip_plan_day', {'p_day': dayId});

  @override
  Future<void> renameDay(String dayId, String? title) =>
      _call('update_trip_plan_day', {
        'p_day': dayId,
        'p_title': title,
        'p_clear_title': title == null || title.trim().isEmpty,
      });

  @override
  Future<String> addStop(
    String dayId,
    String placeId, {
    String? beforeStopId,
    String? note,
  }) async {
    final result = await _call('add_trip_plan_stop', {
      'p_day': dayId,
      'p_place': placeId,
      'p_before_stop': beforeStopId,
      'p_note': note,
    });
    if (result is! String) throw const PlanFailure(PlanFailureKind.unknown);
    return result;
  }

  @override
  Future<void> moveStop(String stopId, String dayId, {String? beforeStopId}) =>
      _call('move_trip_plan_stop', {
        'p_stop': stopId,
        'p_day': dayId,
        'p_before_stop': beforeStopId,
      });

  @override
  Future<void> removeStop(String stopId, {bool toPlacesList = false}) => _call(
    'remove_trip_plan_stop',
    {'p_stop': stopId, 'p_to_list': toPlacesList},
  );

  @override
  Future<void> setDayOrder(String dayId, List<String> stopIds) =>
      _call('set_trip_plan_day_order', {'p_day': dayId, 'p_stop_ids': stopIds});

  @override
  Future<void> setStopNote(String stopId, String? note) =>
      _call('set_trip_plan_stop_note', {'p_stop': stopId, 'p_note': note});

  @override
  Future<void> addPlace(String planId, String placeId, {String? note}) => _call(
    'add_trip_plan_place',
    {'p_plan': planId, 'p_place': placeId, 'p_note': note},
  );

  @override
  Future<void> removePlace(String planId, String placeId) =>
      _call('remove_trip_plan_place', {'p_plan': planId, 'p_place': placeId});

  Map<String, Object?> _customArgs(CustomPlaceDraft place) => {
    'p_name': place.name,
    'p_address': place.address,
    'p_lat': place.lat,
    'p_lng': place.lng,
    'p_county_code': place.countyCode,
    'p_source': place.source.name,
  };

  @override
  Future<String> addCustomStop(
    String dayId,
    CustomPlaceDraft place, {
    String? beforeStopId,
  }) async {
    final result = await _call('add_trip_plan_custom_stop', {
      'p_day': dayId,
      ..._customArgs(place),
      'p_before_stop': beforeStopId,
    });
    if (result is! String) throw const PlanFailure(PlanFailureKind.unknown);
    return result;
  }

  @override
  Future<void> addCustomPlace(String planId, CustomPlaceDraft place) =>
      _call('add_trip_plan_custom_place', {
        'p_plan': planId,
        ..._customArgs(place),
      });

  @override
  Future<void> removeCustomPlace(String planId, String customId) => _call(
    'remove_trip_plan_custom_place',
    {'p_plan': planId, 'p_custom': customId},
  );

  @override
  Future<void> addCustomIdeaToDay(String dayId, String customId) => _call(
    'add_trip_plan_custom_idea_to_day',
    {'p_day': dayId, 'p_custom': customId},
  );

  @override
  Future<void> saveDayRoute(
    String dayId, {
    required String stopsKey,
    required int distanceM,
    required int durationS,
    required List<int> countyCodes,
  }) => _call('set_trip_plan_day_route', {
    'p_day': dayId,
    'p_stops_key': stopsKey,
    'p_distance_m': distanceM,
    'p_duration_s': durationS,
    'p_county_codes': countyCodes,
  });

  @override
  Future<int> convertSavedTrips() async {
    final result = await _call('convert_saved_trips');
    return result is num ? result.toInt() : 0;
  }
}
