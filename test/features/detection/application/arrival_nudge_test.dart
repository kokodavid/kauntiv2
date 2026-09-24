import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaunti47_v2/src/counties/county_paths.dart';
import 'package:kaunti47_v2/src/features/detection/application/arrival_nudge.dart';
import 'package:kaunti47_v2/src/features/detection/domain/arrival_nudge_rules.dart';
import 'package:kaunti47_v2/src/features/detection/domain/visit_models.dart';
import 'package:kaunti47_v2/src/features/discover/application/explore_providers.dart';
import 'package:kaunti47_v2/src/features/discover/data/discover_detail_repository.dart';
import 'package:kaunti47_v2/src/features/discover/domain/county_detail.dart';
import 'package:kaunti47_v2/src/features/discover/domain/place_detail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeDetail implements DiscoverDetailRepository {
  var fail = false;
  final loaded = <int>[];

  @override
  Future<CountyDetailData> countyDetail(int countyCode) async {
    if (fail) throw StateError('offline');
    loaded.add(countyCode);
    return CountyDetailData(
      county: CountyPaths.byCode[countyCode]!,
      aboutBlurb: '',
      quickFacts: const CountyQuickFacts(),
      places: const [],
      personalStatusLabel: 'NOT VISITED YET',
      isHeld: false,
    );
  }

  @override
  Future<PlaceDetailData> placeDetail(String placeId) =>
      throw UnimplementedError();

  @override
  Future<void> setPlaceSaved({
    required int countyCode,
    required String placeId,
    required bool saved,
  }) async {}
}

void main() {
  final entered = DateTime.utc(2026, 9, 24, 8);
  final nairobi = CountyArrivalNudge(countyCode: 47, enteredAt: entered);
  late _FakeDetail detail;

  ProviderContainer container() {
    final c = ProviderContainer(
      overrides: [discoverDetailRepositoryProvider.overrideWithValue(detail)],
    );
    addTearDown(c.dispose);
    return c;
  }

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    detail = _FakeDetail();
  });

  test('offers a new crossing with its county loaded', () async {
    final c = container();
    await c.read(pendingArrivalNudgeProvider.notifier).offer([nairobi]);
    final pending = c.read(pendingArrivalNudgeProvider);
    expect(pending?.nudge, nairobi);
    expect(pending?.county.county.code, 47);
  });

  test('the home county never nudges', () async {
    final c = container();
    await c.read(pendingArrivalNudgeProvider.notifier).offer([
      nairobi,
    ], homeCountyCode: 47);
    expect(c.read(pendingArrivalNudgeProvider), isNull);
    expect(detail.loaded, isEmpty);
  });

  test('once taken, the same crossing is not offered again', () async {
    final c = container();
    final notifier = c.read(pendingArrivalNudgeProvider.notifier);
    await notifier.offer([nairobi]);
    expect(notifier.take()?.nudge, nairobi);
    expect(c.read(pendingArrivalNudgeProvider), isNull);
    await Future<void>.delayed(Duration.zero);

    final shown = await c.read(arrivalNudgeHistoryProvider).shownKeys();
    expect(shown, {ArrivalNudgeRules.keyFor(47, entered)});
    await notifier.offer([nairobi]);
    expect(c.read(pendingArrivalNudgeProvider), isNull);
  });

  test('a failed load is retried next cycle', () async {
    final c = container();
    final notifier = c.read(pendingArrivalNudgeProvider.notifier);
    detail.fail = true;
    await notifier.offer([nairobi]);
    expect(c.read(pendingArrivalNudgeProvider), isNull);

    detail.fail = false;
    await notifier.offer([nairobi]);
    expect(c.read(pendingArrivalNudgeProvider)?.nudge, nairobi);
  });

  test('clear forgets what was shown', () async {
    final history = container().read(arrivalNudgeHistoryProvider);
    await history.markShown(nairobi);
    await history.clear();
    expect(await history.shownKeys(), isEmpty);
  });
}
