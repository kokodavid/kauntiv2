/// A Trip recorded for a plan day.
class PlanDayRecording {
  const PlanDayRecording({
    required this.dayId,
    required this.journeyId,
    this.startedAt,
  });

  final String dayId;
  final String journeyId;
  final DateTime? startedAt;

  static PlanDayRecording? fromJson(Object? json) {
    if (json is! Map ||
        json['day_id'] is! String ||
        json['journey_id'] is! String) {
      return null;
    }
    return PlanDayRecording(
      dayId: json['day_id'] as String,
      journeyId: json['journey_id'] as String,
      startedAt: DateTime.tryParse('${json['started_at']}'),
    );
  }
}
