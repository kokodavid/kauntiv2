import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaunti47_v2/src/counties/county_paths.dart';
import 'package:kaunti47_v2/src/features/discover/application/discover_detail_actions.dart';
import 'package:kaunti47_v2/src/features/discover/data/county_news_flag_repository.dart';
import 'package:kaunti47_v2/src/features/discover/data/discover_detail_repository.dart';
import 'package:kaunti47_v2/src/features/discover/domain/county_detail.dart';
import 'package:kaunti47_v2/src/features/discover/domain/place_category.dart';
import 'package:kaunti47_v2/src/features/discover/domain/place_detail.dart';
import 'package:kaunti47_v2/src/features/discover/presentation/place_detail_screen.dart';

class _Places implements DiscoverDetailRepository {
  @override
  Future<PlaceDetailData> placeDetail(String placeId) async => PlaceDetailData(
    id: placeId,
    title: 'Nairobi National Museum',
    category: PlaceCategory.heritage,
    county: CountyPaths.all.first,
    description: 'Museum',
    images: const [],
    source: 'Kaunti47',
    saved: false,
    latitude: -1.273,
    longitude: 36.814,
  );

  @override
  Future<CountyDetailData> countyDetail(int countyCode) =>
      throw UnimplementedError();

  @override
  Future<void> setPlaceSaved({
    required int countyCode,
    required String placeId,
    required bool saved,
  }) async {}
}

void main() {
  testWidgets('Get Route waits for the chosen handoff without a second tap', (
    tester,
  ) async {
    final complete = Completer<void>();
    var calls = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: PlaceDetailScreen(
          placeId: 'place-1',
          actions: DiscoverDetailActions(
            repository: _Places(),
            countyNewsFlags: _EnabledNewsFlags(),
          ),
          onGetRoute: (context, place) {
            expect(place.id, 'place-1');
            calls++;
            return complete.future;
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Get Route'));
    await tester.pump();
    expect(calls, 1);
    expect(find.text('Get Route'), findsNothing);
    complete.complete();
    await tester.pumpAndSettle();
    expect(find.text('Get Route'), findsOneWidget);
  });
}

class _EnabledNewsFlags implements CountyNewsFlagRepository {
  @override
  Future<bool> isEnabled() async => true;
}
