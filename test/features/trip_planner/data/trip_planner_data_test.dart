import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:kaunti47_v2/src/features/trip_planner/data/county_shapes_source.dart';
import 'package:kaunti47_v2/src/features/trip_planner/data/mapbox_directions_client.dart';
import 'package:kaunti47_v2/src/features/trip_planner/domain/trip_route.dart';

void main() {
  test('parses a Directions response', () {
    final route = MapboxDirectionsClient.parse('''
{"routes":[{"distance":12345.6,"duration":1500,
 "geometry":{"type":"LineString","coordinates":[[36.8,-1.3],[36.9,-1.2]]}}]}
''');
    expect(route.points.length, 2);
    expect(route.points.first.lat, -1.3);
    expect(route.points.first.lng, 36.8);
    expect(route.distanceLabel, '12 km');
    expect(route.durationLabel, '25 min');
  });

  test('asks for the route through the stops, in order', () async {
    Uri? asked;
    final client = MapboxDirectionsClient(
      accessToken: 'test-token',
      client: MockClient((request) async {
        asked = request.url;
        return http.Response(
          '{"routes":[{"distance":1000,"duration":60,'
          '"geometry":{"type":"LineString","coordinates":[[36.8,-1.3]]}}]}',
          200,
        );
      }),
    );
    await client.drive(
      fromLat: -1.0,
      fromLng: 36.0,
      toLat: -3.0,
      toLng: 38.0,
      via: const [TripRoutePoint(-1.5, 36.5), TripRoutePoint(-2.0, 37.0)],
    );
    expect(
      asked?.path,
      '/directions/v5/mapbox/driving/36.0,-1.0;36.5,-1.5;37.0,-2.0;38.0,-3.0',
    );
  });

  test('no route is a readable error', () {
    expect(
      () => MapboxDirectionsClient.parse('{"routes":[]}'),
      throwsA(isA<TripRouteException>()),
    );
    expect(
      () => MapboxDirectionsClient.parse('not json'),
      throwsA(isA<TripRouteException>()),
    );
  });

  test('labels', () {
    const long = TripRoute(
      points: [],
      distanceMeters: 4200,
      durationSeconds: 3900,
    );
    expect(long.distanceLabel, '4.2 km');
    expect(long.durationLabel, '1 h 5 min');
  });

  test('parses polygon and multipolygon boundaries with holes', () {
    final shapes = CountyShapesSource.parse('''
{"type":"FeatureCollection","features":[
 {"type":"Feature","properties":{"code":1},
  "geometry":{"type":"Polygon","coordinates":[
   [[0,0],[10,0],[10,10],[0,10],[0,0]],
   [[4,4],[6,4],[6,6],[4,6],[4,4]]]}},
 {"type":"Feature","properties":{"code":2},
  "geometry":{"type":"MultiPolygon","coordinates":[
   [[[20,0],[30,0],[30,10],[20,10],[20,0]]]]}}
]}
''');
    expect(shapes.map((s) => s.code), [1, 2]);
    expect(shapes[0].contains(1, 1), isTrue);
    expect(shapes[0].contains(5, 5), isFalse);
    expect(shapes[1].contains(5, 25), isTrue);
  });
}
