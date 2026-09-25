import 'package:flutter_test/flutter_test.dart';
import 'package:kaunti47_v2/src/features/journeys/data/supabase_journey_repository.dart';

void main() {
  test('reads every page until a short one', () async {
    const size = SupabaseJourneyRepository.pageSize;
    final total = size * 2 + 17;
    final ranges = <(int, int)>[];
    final rows = await SupabaseJourneyRepository.readAllPages((from, to) async {
      ranges.add((from, to));
      final end = to + 1 < total ? to + 1 : total;
      return [
        for (var i = from; i < end; i++) {'n': i},
      ];
    });
    expect(rows, hasLength(total));
    expect(rows.last['n'], total - 1);
    expect(ranges, [
      (0, size - 1),
      (size, 2 * size - 1),
      (2 * size, 3 * size - 1),
    ]);
  });

  test('an exact multiple ends on an empty page', () async {
    const size = SupabaseJourneyRepository.pageSize;
    var calls = 0;
    final rows = await SupabaseJourneyRepository.readAllPages((from, to) async {
      calls++;
      return from >= size
          ? []
          : [
              for (var i = 0; i < size; i++) {'n': i},
            ];
    });
    expect(rows, hasLength(size));
    expect(calls, 2);
  });
}
