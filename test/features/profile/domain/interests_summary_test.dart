import 'package:flutter_test/flutter_test.dart';
import 'package:kaunti47_v2/src/features/profile/domain/place_interest.dart';

void main() {
  test('interestsSummary reads Not set when empty', () {
    expect(interestsSummary(const []), 'Not set');
  });

  test('interestsSummary lists picks and counts the rest', () {
    expect(interestsSummary(const [PlaceInterest.water]), 'Waterfalls');
    final text = interestsSummary(const [
      PlaceInterest.water,
      PlaceInterest.coast,
      PlaceInterest.food,
    ]);
    expect(text, endsWith('+1'));
  });
}
