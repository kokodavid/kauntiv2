import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaunti47_v2/src/config/app_config.dart';
import 'package:kaunti47_v2/src/core/services/app_config_provider.dart';
import 'package:kaunti47_v2/src/features/journeys/application/journey_entitlement.dart';
import 'package:kaunti47_v2/src/features/journeys/application/journey_history.dart';
import 'package:kaunti47_v2/src/features/journeys/application/journey_recorder.dart';
import 'package:kaunti47_v2/src/features/journeys/data/local_journey_repository.dart';
import 'package:kaunti47_v2/src/features/journeys/domain/journey_destination.dart';
import 'package:kaunti47_v2/src/features/journeys/domain/journey_fix.dart';
import 'package:kaunti47_v2/src/features/journeys/domain/journey_summary.dart';
import 'package:kaunti47_v2/src/features/journeys/domain/pro_status.dart';
import 'package:kaunti47_v2/src/features/journeys/presentation/journey_card_skeleton.dart';
import 'package:kaunti47_v2/src/features/journeys/presentation/journey_history_section.dart';
import 'package:kaunti47_v2/src/features/journeys/presentation/journey_start_card.dart';

class _Recorder extends JourneyRecorder {
  _Recorder(this.error);

  final Exception error;

  @override
  LocalJourneySession? build() => null;

  @override
  Future<void> start({DateTime? now, JourneyDestination? destination}) async =>
      throw error;
}

class _TrialUsage extends JourneyTrialUsage {
  @override
  JourneyTrialStatus? build() => JourneyTrialStatus(
    tripsUsed: 3,
    tripLimit: 3,
    resetsAt: DateTime.utc(2026, 11),
  );
}

class _History extends JourneyHistoryList {
  _History(this.history);

  final JourneyHistory history;
  final deleted = <String>[];
  final renamed = <(String, String)>[];

  @override
  Future<JourneyHistory> build() async => history;

  @override
  Future<void> delete(JourneySummary journey) async => deleted.add(journey.id);

  @override
  Future<void> rename(JourneySummary journey, String title) async =>
      renamed.add((journey.id, title));
}

class _Pending extends JourneyHistoryList {
  _Pending(this.pending);

  final Completer<JourneyHistory> pending;

  @override
  Future<JourneyHistory> build() => pending.future;
}

Widget _app<T>(Widget child, List<T> overrides) => ProviderScope(
  overrides: [
    // No Mapbox token: Journey cards show the plain fill, no route load.
    appConfigProvider.overrideWithValue(const AppConfig.dev()),
    ...overrides.cast(),
  ],
  child: MaterialApp(home: Scaffold(body: child)),
);

void main() {
  testWidgets('an exhausted free account sees limit details, not checkout', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(const JourneyStartCard(), [
        journeyTrialUsageProvider.overrideWith(_TrialUsage.new),
      ]),
    );
    await tester.pump();

    expect(find.text('Details'), findsOneWidget);
    expect(find.text('Start Trip'), findsNothing);
    await tester.tap(find.text('Details'));
    await tester.pumpAndSettle();
    expect(
      find.text(
        "You've recorded 3 Trips this month, the limit on the free plan. Upgrade to Pro for unlimited Trips, or try again after it resets on 1 Nov.",
      ),
      findsOneWidget,
    );
  });

  testWidgets('Start with the free Trip limit used up explains it', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(const JourneyStartCard(), [
        journeyRecorderProvider.overrideWith(
          () => _Recorder(const JourneyTrialExhausted()),
        ),
      ]),
    );
    await tester.tap(find.text('Start Trip'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text("You've used your free Trips"), findsOneWidget);
  });

  testWidgets('Start offline asks for a connection', (tester) async {
    await tester.pumpWidget(
      _app(const JourneyStartCard(), [
        journeyRecorderProvider.overrideWith(
          () => _Recorder(const JourneyProCheckUnavailable()),
        ),
      ]),
    );
    await tester.tap(find.text('Start Trip'));
    await tester.pump();
    expect(
      find.text('Connect to the internet to start a Trip.'),
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
    await tester.tap(find.text('Start Trip'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 750));
    await tester.tap(find.text('Settings'));
    expect(opened, 1);
  });

  testWidgets('history shows waiting and uploaded Journeys', (tester) async {
    final start = DateTime(2026, 9, 25, 9);
    final opened = <String>[];
    await tester.pumpWidget(
      _app(
        SingleChildScrollView(
          child: JourneyHistorySection(onOpen: (_, id) => opened.add(id)),
        ),
        [
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
        ],
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Waiting to upload'), findsOneWidget);
    expect(find.text('1 h 05 min · 12 km'), findsOneWidget);
    expect(find.textContaining("You're offline"), findsOneWidget);
    await tester.tap(find.text('Nairobi loop'));
    expect(opened, ['cloud']);
  });

  testWidgets('history shows shimmering cards while it loads', (tester) async {
    final pending = Completer<JourneyHistory>();
    await tester.pumpWidget(
      _app(const JourneyHistorySection(), [
        journeyHistoryListProvider.overrideWith(() => _Pending(pending)),
      ]),
    );
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(JourneyCardsLoading), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
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
    expect(find.textContaining('No Trips yet'), findsOneWidget);
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

    await tester.tap(find.byTooltip('Trip options'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(history.deleted, isEmpty);

    await tester.tap(find.byTooltip('Trip options'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    expect(history.deleted, ['cloud']);
  });

  testWidgets('a Trip is renamed from the card menu', (tester) async {
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

    await tester.tap(find.byTooltip('Trip options'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Rename'));
    await tester.pumpAndSettle();
    expect(find.text('Rename this Trip'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'Forest loop');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(history.renamed, [('cloud', 'Forest loop')]);
  });
}
