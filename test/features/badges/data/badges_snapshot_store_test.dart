import 'package:flutter_test/flutter_test.dart';
import 'package:kaunti47_v2/src/features/badges/data/badges_snapshot_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('a saved collection reads back for the same account only', () async {
    const store = BadgesSnapshotStore();
    final now = DateTime.utc(2026, 10, 12, 9);
    await store.write(
      'a',
      visitStates: {1: 'explored', 2: 'passed_through'},
      ranks: {1: 'regular'},
      now: now,
      firstStampAt: DateTime.utc(2026, 3, 9, 8),
    );
    final back = await store.read('a');
    expect(back!.savedAt, now);
    expect(back.visitStates, {1: 'explored', 2: 'passed_through'});
    expect(back.ranks, {1: 'regular'});
    expect(back.firstStampAt, DateTime.utc(2026, 3, 9, 8));
    expect(await store.read('b'), isNull);
  });
}
