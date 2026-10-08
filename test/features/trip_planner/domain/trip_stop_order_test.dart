import 'package:flutter_test/flutter_test.dart';
import 'package:kaunti47_v2/src/core/domain/map_place.dart';
import 'package:kaunti47_v2/src/features/trip_planner/domain/trip_stop_order.dart';

MapPlace place(String id, double lat, double lng) =>
    MapPlace(id: id, name: id, type: 'park', countyCode: 1, lat: lat, lng: lng);

void main() {
  test('orders stops along the way from the start to the destination', () {
    // Start at lat 0, destination at lat 3: stops fall in latitude order.
    final ordered = TripStopOrder.order(
      fromLat: 0,
      fromLng: 37,
      toLat: 3,
      toLng: 37,
      stops: [place('c', 2, 37), place('a', 0.5, 37), place('b', 1.2, 37)],
    );
    expect(ordered.map((p) => p.id), ['a', 'b', 'c']);
  });

  test('does not go to a far stop first when it is past the destination', () {
    final ordered = TripStopOrder.order(
      fromLat: 0,
      fromLng: 37,
      toLat: 1,
      toLng: 37,
      stops: [place('far', 5, 37), place('near', 0.4, 37)],
    );
    expect(ordered.first.id, 'near');
  });

  test('leaves zero or one stop as it is', () {
    expect(
      TripStopOrder.order(
        fromLat: 0,
        fromLng: 0,
        toLat: 1,
        toLng: 1,
        stops: const [],
      ),
      isEmpty,
    );
  });

  test('warns when a chosen order is much longer than the shortest', () {
    final stops = [place('c', 2, 37), place('a', 0.5, 37), place('b', 1.2, 37)];
    // Shortest is a, b, c. Going c, a, b doubles back by hundreds of km.
    final extra = TripStopOrder.extraMeters(
      fromLat: 0,
      fromLng: 37,
      toLat: 3,
      toLng: 37,
      chosen: stops,
    );
    expect(extra, greaterThan(TripStopOrder.warnExtraMeters));
  });

  test('does not warn for the shortest order or a small difference', () {
    final best = [place('a', 0.5, 37), place('b', 1.2, 37)];
    expect(
      TripStopOrder.extraMeters(
        fromLat: 0,
        fromLng: 37,
        toLat: 3,
        toLng: 37,
        chosen: best,
      ),
      0,
    );
  });
}
