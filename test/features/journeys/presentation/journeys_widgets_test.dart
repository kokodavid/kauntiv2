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
import 'package:kaunti47_v2/src/features/journeys/domain/journey_transport_mode.dart';
import 'package:kaunti47_v2/src/features/journeys/domain/pro_status.dart';
import 'package:kaunti47_v2/src/features/journeys/presentation/journey_card_skeleton.dart';
import 'package:kaunti47_v2/src/features/journeys/presentation/journey_history_section.dart';
import 'package:kaunti47_v2/src/features/journeys/presentation/journey_start_card.dart';

class _Recorder extends JourneyRecorder {
  _Recorder(this.error);

  final Exception error;
  JourneyTransportMode? lastMode;

  @override
  LocalJourneySession? build() => null;

  @override
  Future<void> start({
    DateTime? now,
    JourneyDestination? destination,
    JourneyTransportMode? mode,
  }) async {
    lastMode = mode;
    throw error;
  }
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
  child: MaterialApp(
    home: Scaffold(body: SingleChildScrollView(child: child)),
  ),
);

/// Taps Start and then the named mode in the mandatory picker sheet that
/// now always appears first, so recorder.start() actually runs.
Future<void> _startAndPickMode(
  WidgetTester tester, {
  String mode = 'Drive',
}) async {
  await tester.tap(find.text('Start'));
  await tester.pumpAndSettle();
  await tester.tap(find.text(mode));
  await tester.pump();
}

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
    expect(find.text('Start'), findsNothing);
    await tester.tap(find.text('Details'));
    await tester.pumpAndSettle();
    expect(
      find.text(
        "You've recorded 3 Trips this month, the limit on the free plan. Upgrade to Pro for unlimited Trips, or try again after it resets on 1 Nov.",
      ),
      findsOneWidget,
    );
  });

  testWidgets('Start asks how the Trip is being travelled first', (
    tester,
  ) async {
    final recorder = _Recorder(const JourneyTrialExhausted());
    await tester.pumpWidget(
      _app(const JourneyStartCard(), [
        journeyRecorderProvider.overrideWith(() => recorder),
      ]),
    );
    await tester.tap(find.text('Start'));
    await tester.pumpAndSettle();
    expect(find.text('How are you travelling?'), findsOneWidget);
    expect(find.text('Drive'), findsOneWidget);
    expect(find.text('Walk'), findsOneWidget);
    expect(find.text('Cycle'), findsOneWidget);

    await tester.tap(find.text('Cycle'));
    await tester.pump();
    expect(recorder.lastMode, JourneyTransportMode.cycle);
  });

  testWidgets('dismissing the mode sheet without picking never starts', (
    tester,
  ) async {
    final recorder = _Recorder(const JourneyTrialExhausted());
    await tester.pumpWidget(
      _app(const JourneyStartCard(), [
        journeyRecorderProvider.overrideWith(() => recorder),
      ]),
    );
    await tester.tap(find.text('Start'));
    await tester.pumpAndSettle();
    // Tap outside the sheet to dismiss it instead of picking a mode.
    await tester.tapAt(const Offset(20, 20));
    await tester.pumpAndSettle();
    expect(recorder.lastMode, isNull);
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
    await _startAndPickMode(tester);
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
    await _startAndPickMode(tester);
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
    await _startAndPickMode(tester);
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
    // Only the filter is labelled this way; local cards use their upload
    // status pill.
    expect(find.text('On this phone'), findsOneWidget);
    expect(find.textContaining('1 h 05 min · 12 km'), findsOneWidget);
    expect(find.textContaining("You're offline"), findsOneWidget);
    final cloudTitle = find.text('Nairobi loop');
    await tester.ensureVisible(cloudTitle);
    await tester.tap(cloudTitle);
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
    await tester.tap(find.text('Delete Trip'));
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
    expect(find.text('Rename Trip'), findsOneWidget);
    await tester.enterText(find.byType(TextField).last, 'Forest loop');
    await tester.tap(find.text('Save name'));
    await tester.pumpAndSettle();
    expect(history.renamed, [('cloud', 'Forest loop')]);
  });

  testWidgets('search and filters stay visible even with a single Trip', (
    tester,
  ) async {
    final start = DateTime(2026, 9, 25, 9);
    await tester.pumpWidget(
      _app(const JourneyHistorySection(), [
        journeyHistoryListProvider.overrideWith(
          () => _History(
            JourneyHistory(
              journeys: [
                JourneySummary(
                  id: 'cloud',
                  title: 'Nairobi loop',
                  startedAt: start,
                  endedAt: start.add(const Duration(minutes: 30)),
                  distanceMeters: 5000,
                  isUploaded: true,
                  countyNames: const ['Nairobi'],
                ),
              ],
            ),
          ),
        ),
      ]),
    );
    await tester.pumpAndSettle();

    expect(find.text('Search trips, places, counties'), findsOneWidget);
    expect(find.text('All counties'), findsOneWidget);
    expect(find.text('This month'), findsOneWidget);
    expect(find.text('Quick hops'), findsOneWidget);
  });

  testWidgets("a Trip's card shows the counties it crossed", (tester) async {
    final start = DateTime(2026, 9, 25, 9);
    await tester.pumpWidget(
      _app(const JourneyHistorySection(), [
        journeyHistoryListProvider.overrideWith(
          () => _History(
            JourneyHistory(
              journeys: [
                JourneySummary(
                  id: 'cloud',
                  title: 'Morning drive to Gigiri',
                  startedAt: start,
                  endedAt: start.add(const Duration(minutes: 36)),
                  distanceMeters: 10200,
                  isUploaded: true,
                  countyNames: const ['Kiambu', 'Nairobi'],
                ),
              ],
            ),
          ),
        ),
      ]),
    );
    await tester.pumpAndSettle();

    expect(find.text('This month'), findsOneWidget);
    expect(find.text('Morning drive to Gigiri'), findsOneWidget);
    expect(find.text('Kiambu → Nairobi'), findsOneWidget);
  });

  testWidgets("a Trip's card shows its transport mode", (tester) async {
    final start = DateTime(2026, 9, 25, 9);
    await tester.pumpWidget(
      _app(const JourneyHistorySection(), [
        journeyHistoryListProvider.overrideWith(
          () => _History(
            JourneyHistory(
              journeys: [
                JourneySummary(
                  id: 'cloud',
                  title: 'Forest loop on foot',
                  startedAt: start,
                  endedAt: start.add(const Duration(minutes: 40)),
                  distanceMeters: 3200,
                  isUploaded: true,
                  transportMode: JourneyTransportMode.walk,
                ),
              ],
            ),
          ),
        ),
      ]),
    );
    await tester.pumpAndSettle();

    expect(
      find.descendant(
        of: find.byType(Row),
        matching: find.byIcon(Icons.directions_walk_rounded),
      ),
      findsWidgets,
    );
  });

  testWidgets('picking a county from the sheet narrows the list', (
    tester,
  ) async {
    final start = DateTime(2026, 9, 25, 9);
    await tester.pumpWidget(
      _app(const JourneyHistorySection(), [
        journeyHistoryListProvider.overrideWith(
          () => _History(
            JourneyHistory(
              journeys: [
                JourneySummary(
                  id: 'nairobi',
                  title: 'Nairobi loop',
                  startedAt: start,
                  endedAt: start.add(const Duration(minutes: 30)),
                  distanceMeters: 5000,
                  isUploaded: true,
                  countyNames: const ['Nairobi'],
                ),
                JourneySummary(
                  id: 'nakuru',
                  title: 'Nakuru by the lake',
                  startedAt: start,
                  endedAt: start.add(const Duration(hours: 3)),
                  distanceMeters: 158000,
                  isUploaded: true,
                  countyNames: const ['Nakuru'],
                ),
              ],
            ),
          ),
        ),
      ]),
    );
    await tester.pumpAndSettle();
    expect(find.text('Nairobi loop'), findsOneWidget);
    expect(find.text('Nakuru by the lake'), findsOneWidget);

    await tester.tap(find.text('All counties'));
    await tester.pumpAndSettle();
    expect(find.text('Counties'), findsOneWidget);
    expect(find.text("You've been to 2 of 47"), findsOneWidget);
    // "Nakuru" also names the still-visible background card's county
    // chain, so the tap is scoped to the sheet's own row.
    await tester.tap(
      find.descendant(
        of: find.byType(BottomSheet),
        matching: find.text('Nakuru'),
      ),
    );
    await tester.pump();
    await tester.tap(find.widgetWithText(ElevatedButton, 'Show 1 trip'));
    await tester.pumpAndSettle();

    expect(find.text('Nairobi loop'), findsNothing);
    expect(find.text('Nakuru by the lake'), findsOneWidget);
  });

  testWidgets('picking several counties shows Trips matching any of them', (
    tester,
  ) async {
    final start = DateTime(2026, 9, 25, 9);
    await tester.pumpWidget(
      _app(const JourneyHistorySection(), [
        journeyHistoryListProvider.overrideWith(
          () => _History(
            JourneyHistory(
              journeys: [
                JourneySummary(
                  id: 'nairobi',
                  title: 'Nairobi loop',
                  startedAt: start,
                  endedAt: start.add(const Duration(minutes: 30)),
                  distanceMeters: 5000,
                  isUploaded: true,
                  countyNames: const ['Nairobi'],
                ),
                JourneySummary(
                  id: 'nakuru',
                  title: 'Nakuru by the lake',
                  startedAt: start,
                  endedAt: start.add(const Duration(hours: 3)),
                  distanceMeters: 158000,
                  isUploaded: true,
                  countyNames: const ['Nakuru'],
                ),
                JourneySummary(
                  id: 'mombasa',
                  title: 'Mombasa coast run',
                  startedAt: start,
                  endedAt: start.add(const Duration(hours: 5)),
                  distanceMeters: 300000,
                  isUploaded: true,
                  countyNames: const ['Mombasa'],
                ),
              ],
            ),
          ),
        ),
      ]),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('All counties'));
    await tester.pumpAndSettle();
    // Check two of the three counties - the button should live-update to
    // the union of both, not double-count or require an exact match.
    await tester.tap(
      find.descendant(
        of: find.byType(BottomSheet),
        matching: find.text('Nairobi'),
      ),
    );
    await tester.pump();
    await tester.tap(
      find.descendant(
        of: find.byType(BottomSheet),
        matching: find.text('Nakuru'),
      ),
    );
    await tester.pump();
    expect(find.widgetWithText(ElevatedButton, 'Show 2 trips'), findsOneWidget);
    await tester.tap(find.widgetWithText(ElevatedButton, 'Show 2 trips'));
    await tester.pumpAndSettle();

    expect(find.text('Nairobi loop'), findsOneWidget);
    expect(find.text('Nakuru by the lake'), findsOneWidget);
    expect(find.text('Mombasa coast run'), findsNothing);
    expect(find.text('2 counties'), findsOneWidget);

    // Re-opening and un-checking one county narrows the button back down.
    await tester.tap(find.text('2 counties'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(BottomSheet),
        matching: find.text('Nakuru'),
      ),
    );
    await tester.pump();
    await tester.tap(find.widgetWithText(ElevatedButton, 'Show 1 trip'));
    await tester.pumpAndSettle();

    expect(find.text('Nairobi loop'), findsOneWidget);
    expect(find.text('Nakuru by the lake'), findsNothing);
  });

  testWidgets('"On this phone" narrows the list to unsynced Trips', (
    tester,
  ) async {
    final start = DateTime(2026, 9, 25, 9);
    await tester.pumpWidget(
      _app(const JourneyHistorySection(), [
        journeyHistoryListProvider.overrideWith(
          () => _History(
            JourneyHistory(
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
                  endedAt: start.add(const Duration(minutes: 30)),
                  distanceMeters: 5000,
                  isUploaded: true,
                  countyNames: const ['Nairobi'],
                ),
              ],
            ),
          ),
        ),
      ]),
    );
    await tester.pumpAndSettle();
    expect(find.text('Nairobi loop'), findsOneWidget);
    expect(find.text('Journey on 25 Sep 2026'), findsOneWidget);

    final localFilter = find.byKey(const ValueKey('journeyOnThisPhoneFilter'));
    await tester.ensureVisible(localFilter);
    await tester.tap(localFilter);
    await tester.pumpAndSettle();
    expect(find.text('Journey on 25 Sep 2026'), findsOneWidget);
    expect(find.text('Nairobi loop'), findsNothing);
  });
}
