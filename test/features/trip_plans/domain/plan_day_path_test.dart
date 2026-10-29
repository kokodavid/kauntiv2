import 'package:flutter_test/flutter_test.dart';
import 'package:kaunti47_v2/src/features/trip_plans/data/plan_routing_client.dart';
import 'package:kaunti47_v2/src/features/trip_plans/domain/plan_day.dart';
import 'package:kaunti47_v2/src/features/trip_plans/domain/plan_day_path.dart';
import 'package:kaunti47_v2/src/features/trip_plans/domain/plan_limits.dart';
import 'package:kaunti47_v2/src/features/trip_plans/domain/plan_member.dart';
import 'package:kaunti47_v2/src/features/trip_plans/domain/plan_place.dart';
import 'package:kaunti47_v2/src/features/trip_plans/domain/plan_route.dart';
import 'package:kaunti47_v2/src/features/trip_plans/domain/plan_totals.dart';
import 'package:kaunti47_v2/src/features/trip_plans/domain/trip_plan.dart';

PlanPlace place(String id, double lat, double lng, {int county = 32}) =>
    PlanPlace(
      id: id,
      name: id,
      type: 'waterfall',
      countyCode: county,
      lat: lat,
      lng: lng,
    );

PlanStop stop(String id, double lat, double lng, {int county = 32}) => PlanStop(
  id: id,
  place: place(id, lat, lng, county: county),
);

TripPlan plan(List<PlanDay> days) => TripPlan(
  id: 'p',
  title: 'Trip',
  ownerId: 'me',
  role: PlanRole.owner,
  start: const PlanStart(
    kind: PlanStartKind.currentLocation,
    lat: -1.3,
    lng: 36.8,
  ),
  limits: PlanLimits.free,
  days: days,
);

void main() {
  final day1 = PlanDay(
    id: 'd1',
    number: 1,
    stops: [stop('a', -0.7, 36.4), stop('b', -0.5, 36.1, county: 35)],
    overnightLat: -0.3,
    overnightLng: 36.0,
  );
  final day2 = PlanDay(id: 'd2', number: 2, stops: [stop('c', 0.1, 35.9)]);

  test('Day 1 runs from the start through each stop to tonight\'s stay', () {
    final points = PlanDayPath.waypoints(plan([day1, day2]), day1);
    expect(points, const [
      PlanRoutePoint(-1.3, 36.8),
      PlanRoutePoint(-0.7, 36.4),
      PlanRoutePoint(-0.5, 36.1),
      PlanRoutePoint(-0.3, 36.0),
    ]);
  });

  test('Day 2 starts where Day 1 stayed the night', () {
    final points = PlanDayPath.waypoints(plan([day1, day2]), day2);
    expect(points.first, const PlanRoutePoint(-0.3, 36.0));
    expect(points.length, 2);
  });

  test('without a stay, the next day starts at the last stop', () {
    final noStay = PlanDay(id: 'd1', number: 1, stops: day1.stops);
    final points = PlanDayPath.waypoints(plan([noStay, day2]), day2);
    expect(points.first, const PlanRoutePoint(-0.5, 36.1));
  });

  test('stops without a position are left out of the road', () {
    final odd = PlanDay(
      id: 'd',
      number: 1,
      stops: [
        stop('a', -0.7, 36.4),
        const PlanStop(
          id: 'x',
          place: PlanPlace(id: 'x', name: 'x', type: '', countyCode: 1),
        ),
      ],
    );
    expect(PlanDayPath.stopPoints(odd).length, 1);
  });

  test('counties come from the stops until a fresh route is saved', () {
    expect(PlanDayPath.counties(day1), [32, 35]);
    final saved = PlanDay(
      id: 'd1',
      number: 1,
      stops: day1.stops,
      routeStopsKey: 'a,b',
      distanceM: 1000,
      countyCodes: const [32, 18, 35],
    );
    expect(PlanDayPath.counties(saved), [32, 18, 35]);
  });

  test('totals add routes, fall back to saved ones, and count pending', () {
    final saved = PlanDay(
      id: 'd2',
      number: 2,
      stops: [stop('c', 0.1, 35.9)],
      routeStopsKey: 'c',
      distanceM: 5000,
      durationS: 600,
    );
    final totals = PlanTotals.of(
      [
        day1,
        saved,
        PlanDay(id: 'd3', number: 3, stops: [stop('e', 1, 1)]),
      ],
      routes: {1: (distanceM: 62000, durationS: 4200)},
    );
    expect(totals.stops, 4);
    expect(totals.distanceM, 67000);
    expect(totals.durationS, 4800);
    expect(totals.pending, 1);
  });

  test('the same points make the same routing request', () {
    expect(
      const PlanLegRequest([PlanRoutePoint(1, 2), PlanRoutePoint(3, 4)]),
      const PlanLegRequest([PlanRoutePoint(1, 2), PlanRoutePoint(3, 4)]),
    );
    expect(const PlanLegRequest([PlanRoutePoint(1, 2)]).isRoutable, isFalse);
  });

  test('the Mapbox answer is read into points, distance and time', () {
    const body =
        '{"routes":[{"distance":1234.4,"duration":600.2,'
        '"geometry":{"coordinates":[[36.8,-1.3],[36.4,-0.7]]}}]}';
    final route = MapboxPlanRoutingClient.parse(body);
    expect(route.distanceM, 1234);
    expect(route.durationS, 600);
    expect(route.points.first, const PlanRoutePoint(-1.3, 36.8));
    expect(
      () => MapboxPlanRoutingClient.parse('{"routes":[]}'),
      throwsA(isA<PlanRouteFailure>()),
    );
    expect(
      () => MapboxPlanRoutingClient.parse('nonsense'),
      throwsA(isA<PlanRouteFailure>()),
    );
  });
}
