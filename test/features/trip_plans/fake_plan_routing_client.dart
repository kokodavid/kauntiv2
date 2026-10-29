import 'package:kaunti47_v2/src/features/trip_plans/data/plan_routing_client.dart';
import 'package:kaunti47_v2/src/features/trip_plans/domain/plan_route.dart';

/// A [PlanRoutingClient] for tests: a straight road through the points, or
/// a failure when [fail] is set. Counts calls so caching can be checked.
class FakePlanRoutingClient implements PlanRoutingClient {
  bool fail = false;
  int calls = 0;

  @override
  Future<PlanRoute> drive(List<PlanRoutePoint> points) async {
    calls++;
    if (fail) throw const PlanRouteFailure("Couldn't reach the route service.");
    return PlanRoute(points: points, distanceM: 62000, durationS: 4200);
  }
}
