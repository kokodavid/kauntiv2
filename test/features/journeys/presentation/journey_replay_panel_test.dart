import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaunti47_v2/src/config/app_config.dart';
import 'package:kaunti47_v2/src/core/services/app_config_provider.dart';
import 'package:kaunti47_v2/src/features/journeys/domain/journey_point.dart';
import 'package:kaunti47_v2/src/features/journeys/domain/journey_route.dart';
import 'package:kaunti47_v2/src/features/journeys/presentation/journey_replay_panel.dart';

JourneyPoint _p(int minute) => JourneyPoint(
  recordedAt: DateTime.utc(2026, 9, 25, 10, minute),
  latitude: -1.30 + minute / 1000,
  longitude: 36.82,
  accuracyMeters: 5,
  segmentNumber: 0,
);

Future<void> _pump(WidgetTester tester) => tester.pumpWidget(
  ProviderScope(
    // No Mapbox token in tests: the map shows its placeholder.
    overrides: [appConfigProvider.overrideWithValue(const AppConfig.dev())],
    child: MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: JourneyReplayPanel(
            route: JourneyRoute([for (var m = 0; m <= 10; m++) _p(m)]),
          ),
        ),
      ),
    ),
  ),
);

void main() {
  testWidgets('starts at the start and plays forward', (tester) async {
    await _pump(tester);
    expect(find.text('0:00:00 · 0 m'), findsOneWidget);
    expect(find.text('Show whole route'), findsNothing);

    await tester.tap(find.byTooltip('Play replay'));
    // 11 points over the 30 s minimum at 1×: ~3 s per point.
    await tester.pump(const Duration(seconds: 7));
    expect(find.text('0:00:00 · 0 m'), findsNothing);
    expect(find.text('Show whole route'), findsOneWidget);

    await tester.tap(find.byTooltip('Pause replay'));
    await tester.pump();
    expect(find.byTooltip('Play replay'), findsOneWidget);
  });

  testWidgets('4× plays four times as far in the same time', (tester) async {
    await _pump(tester);
    await tester.tap(find.text('4×'));
    await tester.tap(find.byTooltip('Play replay'));
    await tester.pump(const Duration(seconds: 7));
    // 7 s at 4× reaches the ninth point: 9 minutes in.
    expect(find.textContaining('0:09:00'), findsOneWidget);
    await tester.tap(find.byTooltip('Pause replay'));
  });

  testWidgets('dragging the scrubber jumps and pauses', (tester) async {
    await _pump(tester);
    await tester.drag(find.byType(Slider), const Offset(2000, 0));
    await tester.pump();
    expect(find.textContaining('0:10:00'), findsOneWidget);
    expect(find.byTooltip('Play replay'), findsOneWidget);

    await tester.tap(find.text('Show whole route'));
    await tester.pump();
    expect(find.text('0:00:00 · 0 m'), findsOneWidget);
  });
}
