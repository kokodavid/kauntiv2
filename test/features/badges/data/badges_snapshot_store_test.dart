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
      exploredAt: {1: DateTime.utc(2026, 11, 2, 14)},
    );
    final back = await store.read('a');
    expect(back!.savedAt, now);
    expect(back.visitStates, {1: 'explored', 2: 'passed_through'});
    expect(back.ranks, {1: 'regular'});
    expect(back.firstStampAt, DateTime.utc(2026, 3, 9, 8));
    expect(back.exploredAt, {1: DateTime.utc(2026, 11, 2, 14)});
    expect(await store.read('b'), isNull);
  });

  test('a copy saved before explored dates existed reads as none', () async {
    SharedPreferences.setMockInitialValues({
      'badges.snapshot.a':
          '{"saved_at":"2026-10-12T09:00:00.000Z","visits":{"1":"explored"},'
          '"ranks":{}}',
    });
    final back = await const BadgesSnapshotStore().read('a');
    expect(back!.visitStates, {1: 'explored'});
    expect(back.exploredAt, isEmpty);
  });
}
