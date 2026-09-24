import 'package:flutter_test/flutter_test.dart';
import 'package:kaunti47_v2/src/core/counties/county_boundary_resolver.dart';

void main() {
  test('resolves representative route points to county codes', () {
    const cases = [
      (countyCode: 22, latitude: -1.17496, longitude: 36.8343), // Kiambu
      (countyCode: 16, latitude: -1.28734, longitude: 37.4069), // Machakos
      (countyCode: 17, latitude: -2.166198, longitude: 37.799674), // Makueni
      (countyCode: 47, latitude: -1.292629, longitude: 36.864399), // Nairobi
    ];

    for (final location in cases) {
      expect(
        CountyBoundaryResolver.countyCodeFor(
          latitude: location.latitude,
          longitude: location.longitude,
          minimumInsideDistanceMeters:
              CountyBoundaryResolver.boundaryHysteresisMeters,
        ),
        location.countyCode,
      );
    }
  });

  test('a point outside Kenya resolves to no county', () {
    expect(
      CountyBoundaryResolver.countyCodeFor(latitude: 51.5, longitude: -0.12),
      isNull,
    );
  });

  test('hysteresis rejects a point too close to the boundary', () {
    // Nairobi CBD is well inside Nairobi; demanding it be 50 km inside the
    // polygon can't be met, so the lookup declines rather than guessing.
    expect(
      CountyBoundaryResolver.countyCodeFor(
        latitude: -1.286389,
        longitude: 36.817223,
        minimumInsideDistanceMeters: 50000,
      ),
      isNull,
    );
  });
}
