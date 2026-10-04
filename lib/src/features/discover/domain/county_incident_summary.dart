class CountyIncidentCategoryCount {
  const CountyIncidentCategoryCount({
    required this.category,
    required this.count,
    required this.previousCount,
    required this.changePercent,
  });

  final String category;
  final int count;
  final int previousCount;
  final int? changePercent;
}

class CountyIncidentSeverityCount {
  const CountyIncidentSeverityCount({
    required this.severity,
    required this.count,
  });

  final String severity;
  final int count;
}

class CountyIncidentSummary {
  const CountyIncidentSummary({
    required this.asOf,
    required this.periodDays,
    required this.total,
    required this.previousTotal,
    required this.changePercent,
    required this.categories,
    required this.severities,
  });

  static const defaultPeriodDays = 30;

  final DateTime asOf;
  final int periodDays;
  final int total;
  final int previousTotal;
  final int? changePercent;
  final List<CountyIncidentCategoryCount> categories;
  final List<CountyIncidentSeverityCount> severities;

  List<CountyIncidentCategoryCount> get leadingCategories => categories
      .where((item) => item.count > 0)
      .toList()
    ..sort((a, b) => b.count.compareTo(a.count));
}
