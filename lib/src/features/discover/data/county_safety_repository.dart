import '../domain/county_incident_summary.dart';
import '../domain/county_safety_feed.dart';

abstract interface class CountySafetyRepository {
  Future<CountySafetyFeed> loadCountyFeed({
    required String countyName,
    required DateTime now,
  });

  Future<CountyIncidentSummary> loadCountySummary({
    required String countySlug,
    required int days,
  });
}
