import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaunti47_v2/src/config/app_config.dart';
import 'package:kaunti47_v2/src/core/services/app_config_provider.dart';
import 'package:kaunti47_v2/src/features/journeys/application/journey_key_moments.dart';
import 'package:kaunti47_v2/src/features/journeys/application/journey_views.dart';
import 'package:kaunti47_v2/src/features/journeys/domain/journey_media_capture.dart';
import 'package:kaunti47_v2/src/features/journeys/domain/journey_moments.dart';
import 'package:kaunti47_v2/src/features/journeys/domain/journey_point.dart';
import 'package:kaunti47_v2/src/features/journeys/domain/journey_route.dart';
import 'package:kaunti47_v2/src/features/journeys/domain/journey_summary.dart';
import 'package:kaunti47_v2/src/features/journeys/presentation/journey_replay_playback_bar.dart';
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
  await tester.pump(const Duration(milliseconds: 500));
}

Future<void> _play(WidgetTester tester, String tooltip) async {
  await tester.tap(find.byTooltip(tooltip));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 1)); // start the ticker clock
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
    expect(find.text('Morning drive'), findsOneWidget);
    // The timeline lists every key moment from the start, not just the
    // one replay happens to be paused at.
    expect(find.text('Entered Kiambu'), findsOneWidget);

    await _play(tester, 'Play replay');
    // 11 points over the 30 s minimum at 1×: 3 s per point, so 12 s
    // would pass point 4 without the moment at point 3.
    await tester.pump(const Duration(seconds: 12));
    expect(find.text('Entered Kiambu'), findsOneWidget);
    expect(find.textContaining('0:03:00'), findsOneWidget);

    await _play(tester, 'Continue replay');
    // Still listed - just no longer the "current" one - once replay
    // moves on.
    expect(find.text('Entered Kiambu'), findsOneWidget);
    await tester.pump(const Duration(seconds: 4));
    expect(find.textContaining('0:04:'), findsOneWidget);
    await tester.tap(find.byTooltip('Pause replay'));
    await tester.pump();
  });

  testWidgets('4× plays four times as far in the same time', (tester) async {
    await _pump(tester);
    // Speed is a single pill that cycles with each tap: 1× -> 2× -> 4×.
    await tester.tap(find.text('1×'));
    await tester.pump();
    await tester.tap(find.text('2×'));
    await tester.pump();
    await _play(tester, 'Play replay');
    await tester.pump(const Duration(seconds: 7));
    // 7 s at 4× glides past the ninth point (about 9:20).
    expect(find.textContaining('0:09:'), findsOneWidget);
    await tester.tap(find.byTooltip('Pause replay'));
    await tester.pump();
  });

  testWidgets('scrubbing jumps and pauses; whole route resets', (tester) async {
    await _pump(tester);
    await tester.drag(
      find.byType(JourneyReplayScrubber),
      const Offset(2000, 0),
    );
    await tester.pump();
    expect(find.textContaining('0:10:00'), findsOneWidget);
    expect(find.byTooltip('Play replay'), findsOneWidget);

    await tester.tap(find.text('Whole route'));
    await tester.pump();
    expect(find.text('0:00:00 · 0 m'), findsOneWidget);
  });

  testWidgets(
    'a photo moment pauses the marker there and can be opened full screen',
    (tester) async {
      await _pump(
        tester,
        moments:  [
          JourneyMoment(
            kind: JourneyMomentKind.photo,
            index: 3,
            photo: JourneyMediaItem(
              id: 'p1',
              url: 'https://example.com/p1.jpg',
              capturedAt: DateTime.utc(2026, 9, 25, 10, 3),
            ),
          ),
        ],
      );
      await _play(tester, 'Play replay');
      await tester.pump(const Duration(seconds: 12));
      expect(find.text('Photo taken'), findsOneWidget);

      await tester.tap(find.byType(Image));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(InteractiveViewer), findsOneWidget);
    },
  );

  testWidgets('tapping a moment jumps replay there', (tester) async {
    await _pump(
      tester,
      moments: const [
        JourneyMoment(
          kind: JourneyMomentKind.countyCrossing,
          index: 6,
          name: 'Nairobi',
        ),
      ],
    );
    await tester.tap(find.text('Entered Nairobi'));
    await tester.pump();
    expect(find.textContaining('0:06:00'), findsOneWidget);
    expect(find.byTooltip('Continue replay'), findsOneWidget);
  });
}
