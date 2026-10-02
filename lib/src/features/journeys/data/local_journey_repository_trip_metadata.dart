part of 'local_journey_repository.dart';

Future<JourneyDestination?> _destination(
  JourneyDatabase db,
  String id,
  String userId,
) async {
  final rows = await db
      .customSelect(
        'SELECT destination_place_id, destination_name, '
        'destination_latitude, destination_longitude FROM journey_sessions '
        'WHERE id = ? AND user_id = ?',
        variables: [Variable.withString(id), Variable.withString(userId)],
        readsFrom: {db.journeySessions},
      )
      .get();
  if (rows.isEmpty) return null;
  final row = rows.single.data;
  final placeId = row['destination_place_id'] as String?;
  final name = row['destination_name'] as String?;
  if (placeId == null || name == null) return null;
  return JourneyDestination(
    placeId: placeId,
    name: name,
    latitude: (row['destination_latitude'] as num?)?.toDouble(),
    longitude: (row['destination_longitude'] as num?)?.toDouble(),
  );
}

Future<String?> _customTitle(
  JourneyDatabase db,
  String id,
  String userId,
) async {
  final rows = await db
      .customSelect(
        'SELECT title FROM journey_sessions WHERE id = ? AND user_id = ?',
        variables: [Variable.withString(id), Variable.withString(userId)],
        readsFrom: {db.journeySessions},
      )
      .get();
  if (rows.isEmpty) return null;
  return rows.single.data['title'] as String?;
}

Future<void> _rename(
  JourneyDatabase db,
  String id,
  String userId,
  String title,
) async {
  final trimmed = title.trim();
  if (trimmed.isEmpty || trimmed.length > 120) {
    throw ArgumentError('A Trip name needs 1-120 characters.');
  }
  await _owned(db, id, userId);
  await db.customUpdate(
    'UPDATE journey_sessions SET title = ? WHERE id = ? AND user_id = ?',
    variables: [
      Variable.withString(trimmed),
      Variable.withString(id),
      Variable.withString(userId),
    ],
    updates: {db.journeySessions},
  );
}

Future<bool> _isBlockedByTrialLimit(
  JourneyDatabase db,
  String id,
  String userId,
) async {
  final rows = await db
      .customSelect(
        'SELECT blocked_by_trial_limit FROM journey_sessions '
        'WHERE id = ? AND user_id = ?',
        variables: [Variable.withString(id), Variable.withString(userId)],
        readsFrom: {db.journeySessions},
      )
      .get();
  return rows.isNotEmpty && rows.single.data['blocked_by_trial_limit'] == 1;
}

Future<void> _setBlockedByTrialLimit(
  JourneyDatabase db,
  String id,
  String userId,
  bool blocked,
) async {
  await db.customUpdate(
    'UPDATE journey_sessions SET blocked_by_trial_limit = ? '
    'WHERE id = ? AND user_id = ?',
    variables: [
      Variable.withInt(blocked ? 1 : 0),
      Variable.withString(id),
      Variable.withString(userId),
    ],
    updates: {db.journeySessions},
  );
}

Future<JourneyTransportMode?> _transportMode(
  JourneyDatabase db,
  String id,
  String userId,
) async {
  final rows = await db
      .customSelect(
        'SELECT transport_mode FROM journey_sessions '
        'WHERE id = ? AND user_id = ?',
        variables: [Variable.withString(id), Variable.withString(userId)],
        readsFrom: {db.journeySessions},
      )
      .get();
  if (rows.isEmpty) return null;
  return JourneyTransportMode.fromStorage(
    rows.single.data['transport_mode'] as String?,
  );
}

Future<LocalJourneySession> _owned(
  JourneyDatabase db,
  String id,
  String userId,
) async {
  final row = await (db.select(
    db.journeySessions,
  )..where((t) => t.id.equals(id) & t.userId.equals(userId))).getSingleOrNull();
  if (row == null) throw StateError('Journey not found for this account.');
  return _session(row);
}
