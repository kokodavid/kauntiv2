import 'package:flutter_test/flutter_test.dart';
import 'package:kaunti47_v2/src/features/discover/presentation/explore_pill_counts.dart';

void main() {
  test('pills show only the label while counts are switched off', () {
    expect(exploreShowsPillCounts, isFalse);
    expect(explorePillLabel('All', 71), 'All');
    expect(explorePillLabel('Waterfalls', 4), 'Waterfalls');
  });
}
