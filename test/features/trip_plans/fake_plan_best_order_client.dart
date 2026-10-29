import 'package:kaunti47_v2/src/features/trip_plans/data/plan_best_order_client.dart';
import 'package:kaunti47_v2/src/features/trip_plans/domain/plan_failure.dart';

/// A [PlanBestOrderClient] for tests: answers with [answer], or fails.
class FakePlanBestOrderClient implements PlanBestOrderClient {
  List<String> answer = const [];
  PlanFailureKind? failWith;
  final calls = <String>[];

  @override
  Future<List<String>> order(
    String dayId, {
    required double lat,
    required double lng,
  }) async {
    calls.add('$dayId|$lat|$lng');
    final kind = failWith;
    if (kind != null) throw PlanFailure(kind);
    return answer;
  }
}
