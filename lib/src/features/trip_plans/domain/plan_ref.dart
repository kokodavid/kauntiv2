/// A plan by name only, for "In 2 trips" and the Add to trip list.
class PlanRef {
  const PlanRef({required this.id, required this.title});

  final String id;
  final String title;

  static PlanRef? fromJson(Object? json) {
    if (json is! Map || json['id'] is! String || json['title'] is! String) {
      return null;
    }
    return PlanRef(id: json['id'] as String, title: json['title'] as String);
  }
}
