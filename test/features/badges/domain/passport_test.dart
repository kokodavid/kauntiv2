import 'package:flutter_test/flutter_test.dart';
import 'package:kaunti47_v2/src/features/badges/domain/badge_collection.dart';
import 'package:kaunti47_v2/src/features/badges/domain/county_badge_detail.dart';
import 'package:kaunti47_v2/src/features/badges/domain/county_check_ins.dart';
import 'package:kaunti47_v2/src/features/badges/domain/passport_book.dart';
import 'package:kaunti47_v2/src/features/badges/domain/passport_level.dart';
import 'package:kaunti47_v2/src/features/badges/domain/passport_progress.dart';
import 'package:kaunti47_v2/src/features/badges/domain/passport_regions.dart';
import 'package:kaunti47_v2/src/features/badges/domain/passport_rules.dart';

void main() {
  // 47 Nairobi (local expert), 22 Kiambu (regular), 1 Mombasa (explored),
  // 30 Baringo (passed through), 10 Marsabit (pending).
  final book = PassportBook.fromCollection(
    BadgeCollection.from(
      visitStates: {
        47: 'explored',
        22: 'explored',
        1: 'explored',
        30: 'passed_through',
        10: 'pending',
      },
      ranks: {47: 'local_expert', 22: 'regular'},
    ),
  );

  test('levels: old depth is kept as Bronze and Silver, never lowered', () {
    expect(book.byCode(47)!.level, PassportLevel.silver);
    expect(book.byCode(22)!.level, PassportLevel.bronze);
    expect(book.byCode(1)!.level, PassportLevel.explored);
    expect(book.byCode(30)!.level, PassportLevel.passedThrough);
    expect(book.byCode(10)!.level, PassportLevel.none);
    expect(book.byCode(2)!.level, PassportLevel.none);
  });

  test('pages run by official county code', () {
    expect(book.counties, hasLength(47));
    expect(book.counties.first.name, 'Mombasa');
    expect(book.counties.first.number, '001');
    expect(book.counties.last.name, 'Nairobi');
    expect(book.counties.last.number, '047');
  });

  test('counts and filters', () {
    expect(book.stampedCount, 4);
    expect(book.countFor(PassportFilter.all), 47);
    expect(book.countFor(PassportFilter.inProgress), 4);
    expect(book.countFor(PassportFilter.notStarted), 43);
    expect(book.countFor(PassportFilter.completed), 0);
    expect(book.barLevels.first, PassportLevel.silver);
    expect(book.barLevels.last, PassportLevel.none);
  });

  test('regions follow the handoff', () {
    expect(PassportRegion.of(22), PassportRegion.central);
    expect(PassportRegion.of(47), PassportRegion.nairobi);
    expect(PassportRegion.of(30), PassportRegion.riftValley);
    expect(PassportRegion.of(12), PassportRegion.eastern);
    expect(PassportRegion.of(1), PassportRegion.coast);
    expect(PassportRegion.of(8), PassportRegion.northEastern);
    expect(PassportRegion.of(37), PassportRegion.western);
    expect(PassportRegion.of(43), PassportRegion.nyanza);
    final all = book.regions();
    expect(all.keys.first, PassportRegion.central);
    expect(all.keys.last, PassportRegion.western);
    final central = all[PassportRegion.central]!.map((c) => c.name);
    expect(central, ['Kiambu', 'Kirinyaga', "Murang'a", 'Nyandarua', 'Nyeri']);
    expect(all.values.expand((c) => c), hasLength(47));
  });

  test('search narrows by name and hides empty regions', () {
    final found = book.regions(query: ' kiam ');
    expect(found.keys, [PassportRegion.central]);
    expect(found.values.single.single.name, 'Kiambu');
    expect(book.regions(query: 'zzz'), isEmpty);
  });

  test('next stamp: first stamp for a new traveller, else Explored', () {
    final fresh = PassportBook.fromCollection(
      BadgeCollection.from(visitStates: const {}, ranks: const {}),
    );
    expect(fresh.nextStamp().isFirst, isTrue);
    expect(fresh.nextStamp().county, isNull);
    final next = book.nextStamp();
    expect(next.county!.name, 'Baringo');
    expect(next.level, PassportLevel.explored);
  });

  group('progress', () {
    const rules = PassportRules.standard;

    test('Passed Through works towards Explored by longest visit', () {
      final progress = PassportProgress.of(
        level: PassportLevel.passedThrough,
        detail: const CountyBadgeDetail(lastPassStay: Duration(hours: 1)),
        rules: rules,
      );
      expect(progress.next, PassportLevel.explored);
      expect(progress.fraction, 0.5);
      expect(progress.percent, 50);
      expect(progress.isLater, isFalse);
      expect(
        progress.stampState(PassportLevel.explored),
        PassportStampState.next,
      );
    });

    test('before place verification a metal stamp is Later', () {
      final progress = PassportProgress.of(
        level: PassportLevel.explored,
        detail: const CountyBadgeDetail(placesTotal: 14),
        rules: rules,
      );
      expect(progress.next, PassportLevel.bronze);
      expect(progress.isLater, isTrue);
      expect(progress.rows.map((r) => r.target), [3, 2, 1]);
      expect(
        progress.stampState(PassportLevel.explored),
        PassportStampState.earned,
      );
      expect(
        progress.stampState(PassportLevel.bronze),
        PassportStampState.future,
      );
    });

    test('a county with few reviewed places has its targets lowered', () {
      final progress = PassportProgress.of(
        level: PassportLevel.explored,
        detail: const CountyBadgeDetail(placesTotal: 2),
        rules: rules,
      );
      expect(progress.rows[0].target, 2);
      expect(progress.rows[0].adjustedFrom, 3);
      expect(progress.rows[1].target, 2);
    });

    test('Gold has nothing further', () {
      final progress = PassportProgress.of(
        level: PassportLevel.gold,
        detail: const CountyBadgeDetail(),
        rules: rules,
      );
      expect(progress.next, isNull);
      expect(
        progress.stampState(PassportLevel.gold),
        PassportStampState.earned,
      );
    });

    test('not started has no percentage', () {
      final progress = PassportProgress.of(
        level: PassportLevel.none,
        detail: const CountyBadgeDetail(),
        rules: rules,
      );
      expect(progress.next, PassportLevel.passedThrough);
      expect(progress.percent, isNull);
    });
  });

  group('check-ins', () {
    final live = PassportRules.standard.withVerification(live: true);

    test('nothing is earned while verification is off', () {
      const enough = CountyCheckIns(
        places: 10,
        categories: 4,
        visitDays: 3,
        placesTotal: 40,
      );
      expect(PassportRules.standard.metalFor(enough), isNull);
    });

    test('the highest metal the evidence reaches', () {
      CountyCheckIns c(int p, int cat, int d) =>
          CountyCheckIns(places: p, categories: cat, visitDays: d, placesTotal: 40);
      expect(live.metalFor(c(2, 2, 1)), isNull);
      expect(live.metalFor(c(3, 2, 1)), PassportLevel.bronze);
      expect(live.metalFor(c(6, 3, 1)), PassportLevel.bronze); // one day only
      expect(live.metalFor(c(6, 3, 2)), PassportLevel.silver);
      expect(live.metalFor(c(10, 4, 3)), PassportLevel.gold);
    });

    test('a county with few places lowers its own targets', () {
      const small = CountyCheckIns(
        places: 2,
        categories: 1,
        visitDays: 1,
        placesTotal: 2,
      );
      expect(live.metalFor(small), PassportLevel.bronze);
    });

    test('check-ins lift an explored county, never one only passed through',
        () {
      const evidence = CheckInsOverview(
        live: true,
        byCounty: {
          1: CountyCheckIns(
            places: 3,
            categories: 2,
            visitDays: 1,
            placesTotal: 40,
          ),
          30: CountyCheckIns(
            places: 3,
            categories: 2,
            visitDays: 1,
            placesTotal: 40,
          ),
        },
      );
      final lifted = PassportBook.fromCollection(
        BadgeCollection.from(
          visitStates: {1: 'explored', 30: 'passed_through'},
          ranks: const {},
          checkIns: evidence,
        ),
      );
      expect(lifted.byCode(1)!.level, PassportLevel.bronze);
      expect(lifted.byCode(30)!.level, PassportLevel.passedThrough);
    });

    test('old depth is never lowered by thin check-ins', () {
      final kept = PassportBook.fromCollection(
        BadgeCollection.from(
          visitStates: {47: 'explored'},
          ranks: {47: 'local_expert'},
          checkIns: const CheckInsOverview(live: true),
        ),
      );
      expect(kept.byCode(47)!.level, PassportLevel.silver);
    });

    test('the overview survives the offline snapshot round trip', () {
      const overview = CheckInsOverview(
        live: true,
        byCounty: {
          22: CountyCheckIns(
            places: 4,
            categories: 2,
            visitDays: 2,
            placesTotal: 9,
          ),
        },
      );
      final back = CheckInsOverview.fromJson(overview.toJson());
      expect(back.live, isTrue);
      expect(back.of(22).places, 4);
      expect(back.of(22).placesTotal, 9);
      expect(back.of(5).places, 0);
    });
  });
}
