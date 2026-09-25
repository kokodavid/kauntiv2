import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaunti47_v2/src/config/app_config.dart';
import 'package:kaunti47_v2/src/core/services/app_config_provider.dart';
import 'package:kaunti47_v2/src/features/journeys/application/journey_key_moments.dart';
import 'package:kaunti47_v2/src/features/journeys/application/journey_views.dart';
import 'package:kaunti47_v2/src/features/journeys/domain/journey_moments.dart';
import 'package:kaunti47_v2/src/features/journeys/domain/journey_point.dart';
import 'package:kaunti47_v2/src/features/journeys/domain/journey_route.dart';
import 'package:kaunti47_v2/src/features/journeys/domain/journey_summary.dart';
import 'package:kaunti47_v2/src/features/journeys/presentation/journey_replay_screen.dart';

JourneyPoint _p(int minute) => JourneyPoint(
  recordedAt: DateTime.utc(2026, 9, 25, 10, minute),
  latitude: -1.30 + minute / 1000,
  longitude: 36.82,
  accuracyMeters: 5,
  segmentNumber: 0,
);

final _detail = JourneyDetail(
  summary: JourneySummary(
    id: 'j',
    title: 'Morning drive',
    startedAt: DateTime.utc(2026, 9, 25, 10),
    endedAt: DateTime.utc(2026, 9, 25, 10, 10),
    isUploaded: true,
  ),
  route: JourneyRoute([for (var m = 0; m <= 10; m++) _p(m)]),
);

Future<void> _pump(
  WidgetTester tester, {
  List<JourneyMoment> moments = const [],
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        // No Mapbox token in tests: the map shows its placeholder.
        appConfigProvider.overrideWithValue(const AppConfig.dev()),
        journeyDetailProvider('j').overrideWith((ref) async => _detail),
        journeyMomentsProvider('j').overrideWith((ref) async => moments),
      ],
      child: const MaterialApp(home: JourneyReplayScreen(journeyId: 'j')),
    ),
  );
  await tester.pump();
}

Future<void> _play(WidgetTester tester, String tooltip) async {
  await tester.tap(find.byTooltip(tooltip));
  await tester.pump(); // first frame starts the clock
}

void main() {
  testWidgets('pauses at a key moment and continues', (tester) async {
    await _pump(
      tester,
      moments: const [
        JourneyMoment(
          kind: JourneyMomentKind.countyCrossing,
          index: 3,
          name: 'Kiambu',
        ),
      ],
    );
    expect(find.text('0:00:00 · 0 m'), findsOneWidget);
    // The Journey's summary rides in the overlay card.
    expect(find.text('Morning drive'), findsOneWidget);
    expect(find.textContaining('10 min · Started'), findsOneWidget);

    await _play(tester, 'Play replay');
    // 11 points over the 30 s minimum at 1×: 3 s per point, so 12 s
    // would pass point 4 without the moment at point 3.
    await tester.pump(const Duration(seconds: 12));
    expect(find.text('Entered Kiambu'), findsOneWidget);
    expect(find.textContaining('0:03:00'), findsOneWidget);

    await _play(tester, 'Continue replay');
    expect(find.text('Entered Kiambu'), findsNothing);
    await tester.pump(const Duration(seconds: 4));
    expect(find.textContaining('0:04:'), findsOneWidget);
    await tester.tap(find.byTooltip('Pause replay'));
    await tester.pump();
  });

  testWidgets('4× plays four times as far in the same time', (tester) async {
    await _pump(tester);
    await tester.tap(find.text('4×'));
    await _play(tester, 'Play replay');
    await tester.pump(const Duration(seconds: 7));
    // 7 s at 4× glides past the ninth point (about 9:20).
    expect(find.textContaining('0:09:'), findsOneWidget);
    await tester.tap(find.byTooltip('Pause replay'));
    await tester.pump();
  });

  testWidgets('scrubbing jumps and pauses; whole route resets', (tester) async {
    await _pump(tester);
    await tester.drag(find.byType(Slider), const Offset(2000, 0));
    await tester.pump();
    expect(find.textContaining('0:10:00'), findsOneWidget);
    expect(find.byTooltip('Play replay'), findsOneWidget);

    await tester.tap(find.byTooltip('Show whole route'));
    await tester.pump();
    expect(find.text('0:00:00 · 0 m'), findsOneWidget);
  });

  testWidgets('a place near the route can be opened', (tester) async {
    final opened = <String>[];
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appConfigProvider.overrideWithValue(const AppConfig.dev()),
          journeyDetailProvider('j').overrideWith((ref) async => _detail),
          journeyMomentsProvider('j').overrideWith(
            (ref) async => const [
              JourneyMoment(
                kind: JourneyMomentKind.nearbyPlace,
                index: 2,
                name: 'Karura Forest',
                distanceMeters: 2400,
                place: JourneyPlaceMark(
                  id: 'karura',
                  countyCode: 47,
                  name: 'Karura Forest',
                  latitude: -1.24,
                  longitude: 36.83,
                ),
              ),
            ],
          ),
        ],
        child: MaterialApp(
          home: JourneyReplayScreen(
            journeyId: 'j',
            onOpenPlace: (_, id) => opened.add(id),
          ),
        ),
      ),
    );
    await tester.pump();
    await _play(tester, 'Play replay');
    await tester.pump(const Duration(seconds: 10));
    expect(find.text('Karura Forest'), findsOneWidget);
    expect(find.textContaining('2.4 km from your route'), findsOneWidget);
    await tester.tap(find.text('Karura Forest'));
    expect(opened, ['karura']);
  });
}
