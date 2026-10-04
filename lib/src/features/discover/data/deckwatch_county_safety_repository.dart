import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../counties/county_paths.dart';
import '../domain/county_incident_summary.dart';
import '../domain/county_safety_feed.dart';
import 'county_safety_repository.dart';

class DeckwatchCountySafetyRepository implements CountySafetyRepository {
  const DeckwatchCountySafetyRepository();

  static const _baseUrl = String.fromEnvironment(
    'DECKWATCH_API_URL',
    defaultValue: 'https://deckwatch.vercel.app',
  );

  static const windowDays = CountyIncidentSummary.defaultPeriodDays;

  @override
  Future<CountySafetyFeed> loadCountyFeed({
    required String countyName,
    required DateTime now,
  }) async {
    final today = DateTime.utc(now.year, now.month, now.day);
    final firstDay = today.subtract(const Duration(days: windowDays - 1));
    final baseUrl = _baseUrl.endsWith('/')
        ? _baseUrl.substring(0, _baseUrl.length - 1)
        : _baseUrl;
    final uri = Uri.parse('$baseUrl/api/incidents').replace(
      queryParameters: {
        'county': countyName,
        'since': firstDay.toIso8601String(),
      },
    );
    final response = await http.get(uri).timeout(const Duration(seconds: 15));
    if (response.statusCode != 200) {
      throw const FormatException('Deckwatch returned an error.');
    }

    final payload = jsonDecode(response.body);
    if (payload is! Map<String, dynamic> || payload['results'] is! List) {
      throw const FormatException('Deckwatch returned an unexpected feed.');
    }
    final asOf = DateTime.tryParse(payload['asOf'] as String? ?? '') ?? now;
    var excluded = 0;
    final incidents = <CountySafetyIncident>[];
    for (final value in payload['results'] as List) {
      if (value is! Map<String, dynamic>) continue;
      if (value['county'] != countyName || value['isLive'] != true) continue;
      final title = value['title'] as String? ?? '';
      final countyMentions = CountyPaths.all
          .where((county) => _hasCounty(title, county.name))
          .toList();
      if (countyMentions.length == 1 &&
          countyMentions.single.name != countyName) {
        excluded++;
        continue;
      }
      final incident = _parseIncident(value);
      if (incident != null) incidents.add(incident);
    }
    incidents.sort((a, b) => b.reportedAt.compareTo(a.reportedAt));

    return CountySafetyFeed(
      asOf: asOf,
      incidents: List.unmodifiable(incidents),
      excludedCountyMismatches: excluded,
    );
  }

  @override
  Future<CountyIncidentSummary> loadCountySummary({
    required String countySlug,
    required int days,
  }) async {
    if (![7, 30, 90].contains(days)) {
      throw ArgumentError.value(days, 'days');
    }
    final baseUrl = _baseUrl.endsWith('/')
        ? _baseUrl.substring(0, _baseUrl.length - 1)
        : _baseUrl;
    final uri = Uri.parse(
      '$baseUrl/api/counties/${Uri.encodeComponent(countySlug)}/summary',
    ).replace(queryParameters: {'days': '$days'});
    final response = await http.get(uri).timeout(const Duration(seconds: 15));
    if (response.statusCode != 200) {
      throw const FormatException('Deckwatch returned a summary error.');
    }

    final payload = jsonDecode(response.body);
    if (payload is! Map<String, dynamic> ||
        payload['categories'] is! List ||
        payload['severities'] is! List ||
        payload['total'] is! num ||
        payload['previousTotal'] is! num) {
      throw const FormatException('Deckwatch returned an unexpected summary.');
    }
    final categories = <CountyIncidentCategoryCount>[];
    for (final value in payload['categories'] as List) {
      if (value is! Map<String, dynamic> || value['category'] is! String) {
        continue;
      }
      categories.add(
        CountyIncidentCategoryCount(
          category: value['category'] as String,
          count: (value['count'] as num?)?.toInt() ?? 0,
          previousCount: (value['previousCount'] as num?)?.toInt() ?? 0,
          changePercent: (value['changePercent'] as num?)?.toInt(),
        ),
      );
    }
    final severities = <CountyIncidentSeverityCount>[];
    for (final value in payload['severities'] as List) {
      if (value is! Map<String, dynamic> || value['severity'] is! String) {
        continue;
      }
      severities.add(
        CountyIncidentSeverityCount(
          severity: value['severity'] as String,
          count: (value['count'] as num?)?.toInt() ?? 0,
        ),
      );
    }

    return CountyIncidentSummary(
      asOf: DateTime.tryParse(payload['asOf'] as String? ?? '') ??
          DateTime.now().toUtc(),
      periodDays: (payload['periodDays'] as num?)?.toInt() ?? days,
      total: (payload['total'] as num).toInt(),
      previousTotal: (payload['previousTotal'] as num).toInt(),
      changePercent: (payload['changePercent'] as num?)?.toInt(),
      categories: List.unmodifiable(categories),
      severities: List.unmodifiable(severities),
    );
  }

  CountySafetyIncident? _parseIncident(Map<String, dynamic> json) {
    final title = json['title'];
    final sources = json['sources'];
    if (title is! String || sources is! List) return null;
    for (final value in sources) {
      if (value is! Map<String, dynamic>) continue;
      final url = Uri.tryParse(value['url'] as String? ?? '');
      final reportedAt = DateTime.tryParse(json['reportedAt'] as String? ?? '');
      if (url == null ||
          !{'http', 'https'}.contains(url.scheme) ||
          reportedAt == null) {
        continue;
      }
      return CountySafetyIncident(
        id: json['id'] as String? ?? '',
        title: title,
        locationName: json['locationName'] as String? ?? '',
        category: json['category'] as String? ?? 'other',
        severity: json['severity'] as String? ?? 'unknown',
        reportedAt: reportedAt,
        verificationStatus:
            json['verificationStatus'] as String? ?? 'unconfirmed',
        reportCount: (json['reportCount'] as num?)?.toInt() ?? 1,
        sourceName: value['name'] as String? ?? 'Original report',
        sourceUrl: url,
      );
    }
    return null;
  }

  bool _hasCounty(String title, String county) => RegExp(
    r'(?<!\w)' + RegExp.escape(county) + r'(?!\w)',
    caseSensitive: false,
  ).hasMatch(title);
}
