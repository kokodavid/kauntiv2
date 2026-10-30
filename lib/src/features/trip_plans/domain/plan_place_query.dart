/// What the Add places page asks for: words in the name, a county, a type,
/// and how many to bring back (it grows with "Show more"). With nothing set
/// it is every place, by name.
/// Equal queries are the same query, so an answer is reused.
class PlanPlaceQuery {
  const PlanPlaceQuery({
    this.text = '',
    this.countyCode,
    this.type,
    this.limit = pageSize,
  });

  static const pageSize = 30;

  final String text;
  final int? countyCode;
  final String? type;
  final int limit;

  @override
  bool operator ==(Object other) =>
      other is PlanPlaceQuery &&
      other.text.trim() == text.trim() &&
      other.countyCode == countyCode &&
      other.type == type &&
      other.limit == limit;

  @override
  int get hashCode => Object.hash(text.trim(), countyCode, type, limit);
}
