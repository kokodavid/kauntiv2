import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaunti47_v2/src/features/journeys/application/journey_history.dart';
import 'package:kaunti47_v2/src/features/journeys/application/journey_recorder.dart';
import 'package:kaunti47_v2/src/features/journeys/data/local_journey_repository.dart';
import 'package:kaunti47_v2/src/features/journeys/domain/journey_fix.dart';
import 'package:kaunti47_v2/src/features/journeys/domain/journey_summary.dart';
import 'package:kaunti47_v2/src/features/journeys/domain/pro_status.dart';
import 'package:kaunti47_v2/src/features/journeys/presentation/journey_history_section.dart';
import 'package:kaunti47_v2/src/features/journeys/presentation/journey_start_card.dart';

class _Recorder extends JourneyRecorder {
  _Recorder(this.error);

  final Object error;

  @override
  LocalJourneySession? build() => null;

  @override
  Future<void> start({DateTime? now}) async => throw error;
}

class _History extends JourneyHistoryList {
  _History(this.history);

  final JourneyHistory history;
  final deleted = <String>[];

  @override
  Future<JourneyHistory> build() async => history;

  @override
  Future<void> delete(JourneySummary journey) async => deleted.add(journey.id);
}

Widget _app(Widget child, List<Override> overrides) => ProviderScope(
  overrides: overrides,
  child: MaterialApp(home: Scaffold(body: child)),
);

void main() {
  testWidgets('Start without Pro explains Pro', (tester) async {
    await tester.pumpWidget(
      _app(const JourneyStartCard(), [
        journeyRecorderProvider.overrideWith(
          () => _Recorder(const JourneyStartDenied()),
        ),
      ]),
    );
    await tester.tap(find.text('Start Journey'));
    await tester.pumpAndSettle();
    expect(find.text('Journeys are part of Pro'), findsOneWidget);
  });

  testWidgets('Start offline asks for a connection', (tester) async {
    await tester.pumpWidget(
      _app(const JourneyStartCard(), [
        journeyRecorderProvider.overrideWith(
          () => _Recorder(const JourneyProCheckUnavailable()),
        ),
      ]),
    );
    await tester.tap(find.text('Start Journey'));
    await tester.pump();
    expect(
      find.text('Connect to the internet to start a Journey.'),
      findsOneWidget,
    );
  });

  testWidgets('no background permission offers Settings', (tester) async {
    var opened = 0;
    await tester.pumpWidget(
      _app(JourneyStartCard(onOpenSettings: () async => opened++), [
        journeyRecorderProvider.overrideWith(
          () => _Recorder(
            const JourneyLocationException(
              JourneyLocationFailure.backgroundPermissionDenied,
            ),
          ),
        ),
      ]),
    );
    await tester.tap(find.text('Start Journey'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 750));
    await tester.tap(find.text('Settings'));
    expect(opened, 1);
  });

  testWidgets('history shows waiting and uploaded Journeys', (tester) async {
    final start = DateTime(2026, 9, 25, 9);
    final opened = <String>[];
    await tester.pumpWidget(
      _app(JourneyHistorySection(onOpen: (_, id) => opened.add(id)), [
        journeyHistoryListProvider.overrideWith(
          () => _History(
            JourneyHistory(
              cloudUnavailable: true,
              journeys: [
                JourneySummary(
                  id: 'local',
                  title: 'Journey on 25 Sep 2026',
                  startedAt: start,
                  endedAt: start.add(const Duration(minutes: 12)),
                  isUploaded: false,
                ),
                JourneySummary(
                  id: 'cloud',
                  title: 'Nairobi loop',
                  startedAt: start,
                  endedAt: start.add(const Duration(hours: 1, minutes: 5)),
                  distanceMeters: 12400,
                  isUploaded: true,
                ),
              ],
            ),
          ),
        ),
      ]),
    );
    await tester.pumpAndSettle();
    expect(find.text('Waiting to upload'), findsOneWidget);
    expect(find.text('25 Sep 2026 · 1 h 05 min · 12 km'), findsOneWidget);
    expect(find.textContaining("You're offline"), findsOneWidget);
    await tester.tap(find.text('Nairobi loop'));
    expect(opened, ['cloud']);
  });

  testWidgets('no Journeys yet says so', (tester) async {
    await tester.pumpWidget(
      _app(const JourneyHistorySection(), [
        journeyHistoryListProvider.overrideWith(
          () => _History(const JourneyHistory(journeys: [])),
        ),
      ]),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('No Journeys yet'), findsOneWidget);
  });

  testWidgets('a Journey is deleted from the list after confirming', (
    tester,
  ) async {
    final start = DateTime(2026, 9, 25, 9);
    final history = _History(
      JourneyHistory(
        journeys: [
          JourneySummary(
            id: 'cloud',
            title: 'Nairobi loop',
            startedAt: start,
            endedAt: start.add(const Duration(minutes: 30)),
            distanceMeters: 5000,
            isUploaded: true,
          ),
        ],
      ),
    );
    await tester.pumpWidget(
      _app(const JourneyHistorySection(), [
        journeyHistoryListProvider.overrideWith(() => history),
      ]),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Delete Journey'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(history.deleted, isEmpty);

    await tester.tap(find.byTooltip('Delete Journey'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    expect(history.deleted, ['cloud']);
  });
}
