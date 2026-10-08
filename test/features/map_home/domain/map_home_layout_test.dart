import 'package:flutter_test/flutter_test.dart';
import 'package:kaunti47_v2/src/features/map_home/domain/map_home_layout.dart';

MapHomeLayout _pick({
  int claimed = 12,
  int total = 47,
  bool recording = false,
  bool fresh = false,
}) => MapHomeLayoutRules.pick(
  claimedCount: claimed,
  totalCounties: total,
  isTripRecording: recording,
  hasFreshClaim: fresh,
);

void main() {
  group('MapHomeLayoutRules.pick', () {
    test('a fresh claim wins over everything', () {
      expect(_pick(fresh: true, recording: true), MapHomeLayout.claim);
      expect(_pick(fresh: true, claimed: 47), MapHomeLayout.claim);
    });

    test('a recording Trip comes next', () {
      expect(_pick(recording: true), MapHomeLayout.recording);
      expect(_pick(recording: true, claimed: 0), MapHomeLayout.recording);
      expect(_pick(recording: true, claimed: 47), MapHomeLayout.recording);
    });

    test('a finished map is complete', () {
      expect(_pick(claimed: 47), MapHomeLayout.complete);
    });

    test('no counties yet means no finished map', () {
      expect(_pick(claimed: 0, total: 0), MapHomeLayout.newUser);
    });

    test('nothing claimed is a new user', () {
      expect(_pick(claimed: 0), MapHomeLayout.newUser);
    });

    test('anything else is standard', () {
      expect(_pick(), MapHomeLayout.standard);
      expect(_pick(claimed: 46), MapHomeLayout.standard);
    });
  });

  group('MapHomeLayoutRules.isFreshClaim', () {
    final now = DateTime(2026, 10, 8, 12);

    test('needs a claim', () {
      expect(
        MapHomeLayoutRules.isFreshClaim(claimedAt: null, now: now),
        isFalse,
      );
    });

    test('is fresh inside the window', () {
      expect(
        MapHomeLayoutRules.isFreshClaim(
          claimedAt: now.subtract(const Duration(minutes: 5)),
          now: now,
        ),
        isTrue,
      );
    });

    test('goes stale after the window', () {
      expect(
        MapHomeLayoutRules.isFreshClaim(
          claimedAt: now.subtract(MapHomeLayoutRules.claimWindow),
          now: now,
        ),
        isTrue,
      );
      expect(
        MapHomeLayoutRules.isFreshClaim(
          claimedAt: now.subtract(
            MapHomeLayoutRules.claimWindow + const Duration(seconds: 1),
          ),
          now: now,
        ),
        isFalse,
      );
    });

    test('a claim from the future is not fresh', () {
      expect(
        MapHomeLayoutRules.isFreshClaim(
          claimedAt: now.add(const Duration(minutes: 1)),
          now: now,
        ),
        isFalse,
      );
    });

    test('is celebrated once', () {
      final claimedAt = now.subtract(const Duration(minutes: 5));
      expect(
        MapHomeLayoutRules.isFreshClaim(
          claimedAt: claimedAt,
          now: now,
          celebratedAt: claimedAt.add(const Duration(minutes: 1)),
        ),
        isFalse,
      );
      expect(
        MapHomeLayoutRules.isFreshClaim(
          claimedAt: claimedAt,
          now: now,
          celebratedAt: claimedAt.subtract(const Duration(hours: 1)),
        ),
        isTrue,
      );
    });
  });

  group('MapHomeLayoutRules.sections', () {
    test('each layout leads with its own section', () {
      expect(
        MapHomeLayoutRules.sections(MapHomeLayout.claim).first,
        MapHomeSection.celebration,
      );
      expect(
        MapHomeLayoutRules.sections(MapHomeLayout.recording).first,
        MapHomeSection.compactTarget,
      );
      expect(
        MapHomeLayoutRules.sections(MapHomeLayout.newUser).first,
        MapHomeSection.homeCountyTarget,
      );
      expect(
        MapHomeLayoutRules.sections(MapHomeLayout.standard).first,
        MapHomeSection.primaryTarget,
      );
    });

    test('trips are hidden while recording and after a claim', () {
      for (final layout in [MapHomeLayout.recording, MapHomeLayout.claim]) {
        expect(
          MapHomeLayoutRules.sections(layout),
          isNot(contains(MapHomeSection.tripsNear)),
        );
      }
    });

    test('saved plans sit under the target on the standard layout only', () {
      final standard = MapHomeLayoutRules.sections(MapHomeLayout.standard);
      expect(
        standard.indexOf(MapHomeSection.savedPlans),
        standard.indexOf(MapHomeSection.primaryTarget) + 1,
      );
      for (final layout in MapHomeLayout.values) {
        if (layout == MapHomeLayout.standard) continue;
        expect(
          MapHomeLayoutRules.sections(layout),
          isNot(contains(MapHomeSection.savedPlans)),
        );
      }
    });

    test('only the win layouts start expanded', () {
      for (final layout in MapHomeLayout.values) {
        expect(
          MapHomeLayoutRules.startsExpanded(layout),
          layout == MapHomeLayout.claim || layout == MapHomeLayout.complete,
        );
      }
    });
  });
}
