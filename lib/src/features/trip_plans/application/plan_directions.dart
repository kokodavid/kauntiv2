import '../../../core/services/app_external_links.dart';
import '../domain/plan_route.dart';

/// Opens a day's drive in the phone's maps app, stop by stop. False when
/// there is nothing to route or no app could open it.
Future<bool> openPlanDirections(List<PlanRoutePoint> points) {
  if (points.length < 2) return Future.value(false);
  String at(PlanRoutePoint p) => '${p.lat},${p.lng}';
  // Google Maps takes at most nine stops between the ends.
  final between = points.sublist(1, points.length - 1).take(9).map(at);
  final uri = Uri.parse(
    'https://www.google.com/maps/dir/?api=1'
    '&origin=${at(points.first)}&destination=${at(points.last)}'
    '&travelmode=driving'
    '${between.isEmpty ? '' : '&waypoints=${between.join('%7C')}'}',
  );
  return AppExternalLinks.open(uri);
}
