import 'dart:async';
import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/plan_failure.dart';

/// One planner database call: errors come back as a [PlanFailure], and a
/// slow or missing network reads as offline.
Future<Object?> callPlanRpc(
  SupabaseClient client,
  String fn, [
  Map<String, Object?>? params,
]) async {
  try {
    return await client
        .rpc<dynamic>(fn, params: params)
        .timeout(const Duration(seconds: 10));
  } on PostgrestException catch (error) {
    throw PlanFailure(PlanFailureKind.fromCode(error.message));
  } on TimeoutException {
    throw const PlanFailure(PlanFailureKind.offline);
  } on SocketException {
    throw const PlanFailure(PlanFailureKind.offline);
  }
}
