/// What the Add places page asks for: words in the name, a county, a type.
/// Equal queries are the same query, so an answer is reused.
class PlanPlaceQuery {
  const PlanPlaceQuery({this.text = '', this.countyCode, this.type});

  final String text;
  final int? countyCode;
  final String? type;

  /// Search starts from 2 letters, or from a county or type.
  bool get isReady =>
      text.trim().length >= 2 || countyCode != null || type != null;

  @override
  bool operator ==(Object other) =>
      other is PlanPlaceQuery &&
      other.text.trim() == text.trim() &&
      other.countyCode == countyCode &&
      other.type == type;

  @override
  int get hashCode => Object.hash(text.trim(), countyCode, type);
}
