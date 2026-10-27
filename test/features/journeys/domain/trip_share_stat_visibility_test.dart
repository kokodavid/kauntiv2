import 'package:flutter_test/flutter_test.dart';
import 'package:kaunti47_v2/src/features/journeys/domain/trip_share_stat_visibility.dart';

void main() {
  test('sharing default hides only top speed', () {
    const v = TripShareStatVisibility.sharingDefault;
    expect(v.topSpeed, isFalse);
    expect(v.distance && v.averageSpeed && v.elevation, isTrue);
  });

  test('copyWith changes one stat and keeps equality semantics', () {
    final v = TripShareStatVisibility.sharingDefault.copyWith(topSpeed: true);
    expect(v, TripShareStatVisibility.all);
    expect(v.copyWith(distance: false).distance, isFalse);
  });
}
