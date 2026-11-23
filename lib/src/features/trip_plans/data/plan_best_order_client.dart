import 'dart:async';
import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/plan_failure.dart';

/// Works out a short driving order for a day's stops (Pro). The work is
/// done by the `plan-best-order` Edge Function, which holds the Mapbox key
/// and checks Pro, role and the hourly limit.
abstract interface class PlanBestOrderClient {
  /// The day's stop ids in the order to visit, starting from [lat], [lng].
  Future<List<String>> order(
    String dayId, {
    required double lat,
    required double lng,
  });
}

class SupabasePlanBestOrderClient implements PlanBestOrderClient {
  const SupabasePlanBestOrderClient(this.client);

  final SupabaseClient client;

  @override
  Future<List<String>> order(
    String dayId, {
    required double lat,
    required double lng,
  }) async {
    try {
      final response = await client.functions
          .invoke(
            'plan-best-order',
            body: {
              'day_id': dayId,
              'start': {'lat': lat, 'lng': lng},
            },
          )
          .timeout(const Duration(seconds: 20));
      final data = response.data;
      final ids = data is Map ? data['stop_ids'] : null;
      if (ids is! List) throw const PlanFailure(PlanFailureKind.unknown);
      return [
        for (final id in ids)
          if (id is String) id,
      ];
    } on FunctionException catch (error) {
      final details = error.details;
      final code = details is Map ? details['error'] : null;
      throw PlanFailure(PlanFailureKind.fromCode(code is String ? code : null));
    } on TimeoutException {
      throw const PlanFailure(PlanFailureKind.offline);
    } on SocketException {
      throw const PlanFailure(PlanFailureKind.offline);
    }
  }
}
