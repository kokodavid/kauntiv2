import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/services/app_config_provider.dart';
import '../data/plan_routing_client.dart';
import '../domain/plan_route.dart';

part 'plan_routing_providers.g.dart';

/// The routing service. Null in a build without a Mapbox token, where days
/// simply show no road.
@Riverpod(keepAlive: true)
PlanRoutingClient? planRoutingClient(Ref ref) {
  final token = ref.watch(appConfigProvider).mapboxAccessToken;
  return token.isEmpty ? null : MapboxPlanRoutingClient(accessToken: token);
}

/// The road for one day's points. Waits a moment first, so a burst of edits
/// asks once; a good answer is kept for the session, keyed by the points,
/// so the same stops never ask twice. A failure is not kept, so Retry (an
/// invalidate) asks again. Null when there is nothing to route.
Duration? _planDayRouteRetry(int retryCount, Object error) => null;

@Riverpod(retry: _planDayRouteRetry)
Future<PlanRoute?> planDayRoute(Ref ref, PlanLegRequest request) async {
  if (!request.isRoutable) return null;
  final client = ref.watch(planRoutingClientProvider);
  if (client == null) return null;
  await Future<void>.delayed(const Duration(milliseconds: 300));
  if (!ref.mounted) return null;
  final route = await client.drive(request.points);
  if (ref.mounted) ref.keepAlive();
  return route;
}
