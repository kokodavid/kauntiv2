import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaunti47_v2/src/config/app_config.dart';
import 'package:kaunti47_v2/src/core/services/app_config_provider.dart';
import 'package:kaunti47_v2/src/features/journeys/application/journey_key_moments.dart';
import 'package:kaunti47_v2/src/features/journeys/application/journey_recorder.dart';
import 'package:kaunti47_v2/src/features/journeys/application/journey_views.dart';
import 'package:kaunti47_v2/src/features/journeys/data/local_journey_repository.dart';
import 'package:kaunti47_v2/src/features/journeys/domain/journey_recording.dart';
import 'package:kaunti47_v2/src/features/journeys/domain/journey_route.dart';
import 'package:kaunti47_v2/src/features/journeys/presentation/journey_recording_screen.dart';

class _Recorder extends JourneyRecorder {
  _Recorder(this.recording);

  final JourneyRecording recording;

  @override
  LocalJourneySession? build() =>
      LocalJourneySession(id: 'j', recording: recording);
}

void main() {
  testWidgets('recording shows full screen with its controls', (tester) async {
    // Paused 10 minutes in: the clock shows 10 minutes, not the wall time.
    final start = DateTime.now().toUtc().subtract(const Duration(hours: 1));
    final recording = const JourneyRecording.idle()
        .start(start)
        .pause(start.add(const Duration(minutes: 10)));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          // No Mapbox token in tests: the map shows its placeholder.
          appConfigProvider.overrideWithValue(const AppConfig.dev()),
          journeyRecorderProvider.overrideWith(() => _Recorder(recording)),
          activeJourneyRouteProvider.overrideWith(
            (ref) => Stream.value(JourneyRoute(const [])),
          ),
          journeyMapPlacesProvider.overrideWith((ref) async => const []),
        ],
        child: const MaterialApp(home: JourneyRecordingScreen()),
      ),
    );
    await tester.pump();

    expect(find.text('Paused'), findsOneWidget);
    expect(find.text('0:10:00'), findsOneWidget);
    expect(find.text('Resume'), findsOneWidget);
    expect(find.text('Stop'), findsOneWidget);
    expect(find.byTooltip('Minimise'), findsOneWidget);
    expect(find.text('Waiting for your location…'), findsOneWidget);

    // Stop offers save or discard.
    await tester.tap(find.text('Stop'));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Discard'), findsOneWidget);
    expect(find.text('Stop and save'), findsOneWidget);
    await tester.tap(find.text('Keep going'));
    await tester.pump(const Duration(milliseconds: 500));

    // Drop the tree so the clock's timer stops.
    await tester.pumpWidget(const SizedBox());
  });
}
