class CountySafetyIncident {
  const CountySafetyIncident({
    required this.id,
    required this.title,
    required this.locationName,
    required this.category,
    required this.severity,
    required this.reportedAt,
    required this.verificationStatus,
    required this.reportCount,
    required this.sourceName,
    required this.sourceUrl,
  });

  final String id;
  final String title;
  final String locationName;
  final String category;
  final String severity;
  final DateTime reportedAt;
  final String verificationStatus;
  final int reportCount;
  final String sourceName;
  final Uri sourceUrl;

  bool get isSevere => {'high', 'critical', 'severe'}.contains(severity.toLowerCase());
}

class CountySafetyFeed {
  const CountySafetyFeed({
    required this.asOf,
    required this.incidents,
    required this.excludedCountyMismatches,
  });

  final DateTime asOf;
  final List<CountySafetyIncident> incidents;
  /// Reports whose headline names a different single county than the API row.
  final int excludedCountyMismatches;

  int get incidentCount => incidents.length;

  CountySafetyIncident? get latestIncident =>
      incidents.isEmpty ? null : incidents.first;

  /// The most recent incident still worth surfacing as an active alert:
  /// reported within the last 48 hours, corroborated by at least two
  /// outlets, and at least advisory-level severity. Null when nothing in
  /// the feed qualifies. Shared by [CountySafetyAlertBanner] and the "In
  /// the news" card's corner dot, so both read the same definition of
  /// "active" rather than keeping two copies of this window/threshold
  /// logic in sync by hand.
  CountySafetyIncident? get activeAlert {
    final now = DateTime.now().toUtc();
    for (final incident in incidents) {
      final age = now.difference(incident.reportedAt.toUtc());
      if (age.isNegative || age > const Duration(hours: 48)) continue;
      if (incident.reportCount < 2) continue;
      final severity = incident.severity.toLowerCase();
      if (incident.isSevere ||
          {'medium', 'moderate', 'advisory'}.contains(severity)) {
        return incident;
      }
    }
    return null;
  }
}
