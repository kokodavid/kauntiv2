import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaunti47_v2/src/core/domain/place_type.dart';
import 'package:kaunti47_v2/src/core/widgets/place_type_style.dart';

void main() {
  test('country club style resolves synchronously without fallback frames', () {
    for (final value in ['country_club', 'Country clubs']) {
      final type = PlaceType.of(value);
      expect(type, PlaceType.countryClub);
      expect(type.icon, Icons.golf_course);
      expect(type.pinColor, PlaceTypeFamily.other.pinColor);
    }
  });
}
