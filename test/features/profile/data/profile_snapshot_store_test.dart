import 'package:flutter_test/flutter_test.dart';
import 'package:kaunti47_v2/src/features/profile/data/profile_snapshot_store.dart';
import 'package:kaunti47_v2/src/features/profile/domain/public_profile.dart';
import 'package:kaunti47_v2/src/features/profile/domain/trip_stats.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test(
    'profile and stats are saved together and read back per account',
    () async {
      const store = ProfileSnapshotStore();
      final now = DateTime.utc(2026, 10, 12, 9);
      await store.writeProfile(
        'a',
        const PublicProfile(displayName: 'Amina', handle: 'amina_k'),
        now,
      );
      await store.writeStats(
        'a',
        const TripStats(
          tripCount: 4,
          totalDistanceM: 214000,
          longestDistanceM: 90000,
        ),
        now.add(const Duration(minutes: 1)),
      );

      final profile = await store.readProfile('a');
      expect(profile!.displayName, 'Amina');
      expect(profile.handle, 'amina_k');
      expect(profile.avatarUrl, isNull);

      final stats = await store.readStats('a');
      expect(stats!.tripCount, 4);
      expect(stats.totalDistanceKm, 214);
      expect(stats.longestDistanceKm, 90);

      expect(await store.savedAt('a'), now.add(const Duration(minutes: 1)));
      expect(await store.readProfile('b'), isNull);
      expect(await store.readStats('b'), isNull);
      expect(await store.savedAt('b'), isNull);
    },
  );
}
