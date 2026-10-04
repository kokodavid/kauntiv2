import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaunti47_v2/src/features/discover/application/discover_detail_actions.dart';
import 'package:kaunti47_v2/src/features/discover/data/county_news_flag_repository.dart';
import 'package:kaunti47_v2/src/features/discover/data/county_safety_repository.dart';
import 'package:kaunti47_v2/src/features/discover/data/discover_detail_repository.dart';
import 'package:kaunti47_v2/src/features/discover/domain/county_detail.dart';
import 'package:kaunti47_v2/src/features/discover/domain/county_incident_summary.dart';
import 'package:kaunti47_v2/src/features/discover/domain/county_safety_feed.dart';
import 'package:kaunti47_v2/src/features/discover/domain/place_detail.dart';
import 'package:kaunti47_v2/src/features/discover/presentation/county_incident_summary_panel.dart';
import 'package:kaunti47_v2/src/features/discover/presentation/county_safety_alert_banner.dart';
import 'package:kaunti47_v2/src/features/discover/presentation/county_safety_section.dart';

void main() {
  testWidgets('does not show the previous county while the next feed loads', (
    tester,
  ) async {
    final nairobi = Future.value(_feed('Nairobi incident'));
    final kiambu = Completer<CountySafetyFeed>().future;
    final actions = _actions();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CountySafetySection(
            countyName: 'Nairobi',
            countySlug: 'nairobi',
            feed: nairobi,
            actions: actions,
            onRetry: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('Nairobi incident'), findsOneWidget);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CountySafetySection(
            countyName: 'Kiambu',
            countySlug: 'kiambu',
            feed: kiambu,
            actions: actions,
            onRetry: () {},
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.textContaining('Nairobi incident'), findsNothing);
    expect(find.text('Loading news…'), findsOneWidget);
  });

  testWidgets('summary opens the county news sheet', (tester) async {
    final actions = _actions();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CountySafetySection(
            countyName: 'Nairobi',
            countySlug: 'nairobi',
            feed: Future.value(
              _feed('Flooding in Nairobi', excludedCountyMismatches: 1),
            ),
            actions: actions,
            onRetry: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('In the news'), findsOneWidget);
    expect(find.text('1 report · last 30 days'), findsOneWidget);

    await tester.tap(find.text('In the news'));
    await tester.pumpAndSettle();
    expect(find.text('Nairobi · reported incidents'), findsOneWidget);
    expect(find.text('Reported by 2 outlets'), findsOneWidget);
    expect(
      find.textContaining('does not independently verify'),
      findsOneWidget,
    );
    expect(find.text('Reported incidents · last 30 days'), findsOneWidget);
    expect(find.text('12'), findsOneWidget);
    expect(find.textContaining('Crime (7,'), findsOneWidget);
    expect(find.text('3 high/critical reports'), findsOneWidget);
    expect(find.textContaining('+50% vs previous period'), findsOneWidget);
    expect(find.textContaining('excluded because'), findsNothing);
  });

  testWidgets('does not show previous county statistics while next loads', (
    tester,
  ) async {
    final pending = Completer<CountyIncidentSummary>();
    final actions = _actions(
      countySafety: _SwitchingSummaryRepository(pending.future),
    );
    Widget panel(String slug) => MaterialApp(
      home: Scaffold(
        body: CountyIncidentSummaryPanel(
          key: ValueKey(slug),
          countySlug: slug,
          actions: actions,
        ),
      ),
    );

    await tester.pumpWidget(panel('nairobi'));
    await tester.pumpAndSettle();
    expect(find.text('12'), findsOneWidget);

    await tester.pumpWidget(panel('kiambu'));
    await tester.pump();
    expect(find.text('12'), findsNothing);
    expect(find.text('Loading incident statistics…'), findsOneWidget);

    pending.complete(_summary(total: 3));
    await tester.pumpAndSettle();
    expect(find.text('3'), findsOneWidget);
  });

  testWidgets('recent corroborated serious reports show the alert banner', (
    tester,
  ) async {
    final feed = _feed('Flooding in Nairobi', severity: 'high', reportCount: 2);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CountySafetyAlertBanner(
            countyName: 'Nairobi',
            countySlug: 'nairobi',
            feed: Future.value(feed),
            actions: _actions(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('HIGH SEVERITY · LAST 48 HRS'), findsOneWidget);
  });

  testWidgets('single-source items do not produce an alert banner', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CountySafetyAlertBanner(
            countyName: 'Nairobi',
            countySlug: 'nairobi',
            feed: Future.value(
              _feed(
                'Flooding in Nairobi',
                severity: 'critical',
                reportCount: 1,
              ),
            ),
            actions: _actions(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('HIGH SEVERITY · LAST 48 HRS'), findsNothing);
  });
}

DiscoverDetailActions _actions({CountySafetyRepository? countySafety}) =>
    DiscoverDetailActions(
      repository: _UnusedDiscoverRepository(),
      countyNewsFlags: _EnabledNewsFlags(),
      countySafety: countySafety ?? _FakeCountySafetyRepository(),
    );

class _FakeCountySafetyRepository implements CountySafetyRepository {
  @override
  Future<CountySafetyFeed> loadCountyFeed({
    required String countyName,
    required DateTime now,
  }) async => _feed('Feed fixture');

  @override
  Future<CountyIncidentSummary> loadCountySummary({
    required String countySlug,
    required int days,
  }) async => _summary(total: 12, days: days);
}

class _SwitchingSummaryRepository extends _FakeCountySafetyRepository {
  _SwitchingSummaryRepository(this.kiambuSummary);

  final Future<CountyIncidentSummary> kiambuSummary;

  @override
  Future<CountyIncidentSummary> loadCountySummary({
    required String countySlug,
    required int days,
  }) => countySlug == 'kiambu'
      ? kiambuSummary
      : super.loadCountySummary(countySlug: countySlug, days: days);
}

CountyIncidentSummary _summary({required int total, int days = 30}) =>
    CountyIncidentSummary(
      asOf: DateTime.utc(2026, 10, 3),
      periodDays: days,
      total: total,
      previousTotal: 8,
      changePercent: 50,
      categories: const [
        CountyIncidentCategoryCount(
          category: 'crime',
          count: 7,
          previousCount: 4,
          changePercent: 75,
        ),
      ],
      severities: const [
        CountyIncidentSeverityCount(severity: 'high', count: 2),
        CountyIncidentSeverityCount(severity: 'critical', count: 1),
      ],
    );

class _EnabledNewsFlags implements CountyNewsFlagRepository {
  @override
  Future<bool> isEnabled() async => true;
}

CountySafetyFeed _feed(
  String title, {
  String severity = 'low',
  int reportCount = 2,
  DateTime? reportedAt,
  int excludedCountyMismatches = 0,
}) {
  final date =
      reportedAt ?? DateTime.now().toUtc().subtract(const Duration(hours: 3));
  return CountySafetyFeed(
    asOf: date,
    incidents: [
      CountySafetyIncident(
        id: 'feed-test',
        title: title,
        locationName: 'Nairobi CBD',
        category: 'crime',
        severity: severity,
        reportedAt: date,
        verificationStatus: 'unconfirmed',
        reportCount: reportCount,
        sourceName: 'Example News',
        sourceUrl: Uri.https('example.com', '/story'),
      ),
    ],
    excludedCountyMismatches: excludedCountyMismatches,
  );
}

class _UnusedDiscoverRepository implements DiscoverDetailRepository {
  @override
  Future<CountyDetailData> countyDetail(int countyCode) =>
      throw UnimplementedError();

  @override
  Future<PlaceDetailData> placeDetail(String placeId) =>
      throw UnimplementedError();

  @override
  Future<void> setPlaceSaved({
    required int countyCode,
    required String placeId,
    required bool saved,
  }) => throw UnimplementedError();
}
