import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:kaunti47_v2/src/features/discover/data/deckwatch_county_safety_repository.dart';

void main() {
  test('loads a 30-day feed and excludes a clear county mismatch', () async {
    late Uri requestedUri;
    final client = MockClient((request) async {
      requestedUri = request.url;
      return http.Response(
        '{"asOf":"2026-10-03T12:00:00Z","results":['
        '{"id":"one","title":"Flooding in Nairobi","county":"Nairobi",'
        '"locationName":"Nairobi CBD",'
        '"isLive":true,"category":"flood","severity":"high",'
        '"reportedAt":"2026-10-03T09:00:00Z",'
        '"verificationStatus":"unconfirmed","reportCount":1,"sources":['
        '{"name":"News source","url":"https://example.com/story"}]},'
        '{"id":"two","title":"Mine collapse in West Pokot",'
        '"county":"Nairobi","isLive":true,"category":"infrastructure",'
        '"severity":"critical","reportedAt":"2026-10-02T09:00:00Z",'
        '"verificationStatus":"unconfirmed","reportCount":1,"sources":['
        '{"name":"News source","url":"https://example.com/other"}]}]}',
        200,
      );
    });

    final feed = await http.runWithClient(
      () => const DeckwatchCountySafetyRepository().loadCountyFeed(
        countyName: 'Nairobi',
        now: DateTime.utc(2026, 10, 3, 12),
      ),
      () => client,
    );

    expect(requestedUri.queryParameters['county'], 'Nairobi');
    expect(requestedUri.queryParameters['since'], '2026-09-04T00:00:00.000Z');
    expect(feed.incidentCount, 1);
    expect(feed.excludedCountyMismatches, 1);
    expect(feed.incidents.single.locationName, 'Nairobi CBD');
    expect(feed.incidents.single.sourceUrl.host, 'example.com');
  });

  test('loads county incident summary and maps comparison/category fields', () async {
    late Uri requestedUri;
    final client = MockClient((request) async {
      requestedUri = request.url;
      return http.Response(
        '{"county":"Kiambu","slug":"kiambu",'
        '"asOf":"2026-10-03T12:00:00Z","periodDays":30,'
        '"unit":"incidents","total":14,"previousTotal":7,'
        '"changePercent":100,"categories":[{"category":"crime",'
        '"count":5,"previousCount":2,"changePercent":150}],'
        '"severities":[{"severity":"high","count":3}],"dailyTrend":[]}',
        200,
      );
    });

    final summary = await http.runWithClient(
      () => const DeckwatchCountySafetyRepository().loadCountySummary(
        countySlug: 'kiambu',
        days: 30,
      ),
      () => client,
    );

    expect(requestedUri.path, '/api/counties/kiambu/summary');
    expect(requestedUri.queryParameters['days'], '30');
    expect(summary.total, 14);
    expect(summary.previousTotal, 7);
    expect(summary.changePercent, 100);
    expect(summary.leadingCategories.single.category, 'crime');
    expect(summary.leadingCategories.single.count, 5);
    expect(summary.severities.single.severity, 'high');
    expect(summary.severities.single.count, 3);
  });
}
