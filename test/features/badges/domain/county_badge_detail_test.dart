import 'package:flutter_test/flutter_test.dart';
import 'package:kaunti47_v2/src/features/badges/domain/badge_collection.dart';
import 'package:kaunti47_v2/src/features/badges/domain/county_badge_detail.dart';

void main() {
  test('visited: regular needs 3 visits across 3 months', () {
    final step = DepthLadder.nextStep(
      CountyDepth.visited,
      visits: 2,
      months: 1,
    )!;
    expect(step.next, CountyDepth.regular);
    expect(step.visitsNeeded, 1);
    expect(step.monthsNeeded, 2);
    // Two visits in new months cover both.
    expect(step.visitsToGo, 2);
  });

  test('regular: local expert needs 6 visits across 5 months', () {
    final step = DepthLadder.nextStep(
      CountyDepth.regular,
      visits: 5,
      months: 5,
    )!;
    expect(step.next, CountyDepth.localExpert);
    expect(step.visitsToGo, 1);
  });

  test('no next step before earning or at the top', () {
    expect(
      DepthLadder.nextStep(CountyDepth.none, visits: 0, months: 0),
      isNull,
    );
    expect(
      DepthLadder.nextStep(CountyDepth.localExpert, visits: 9, months: 7),
      isNull,
    );
  });
}
