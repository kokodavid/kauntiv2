import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/county_check_ins.dart';

/// The last badge collection that loaded, kept on the phone (one per
/// account) so the Collection tab still opens without a connection.
class BadgesSnapshot {
  const BadgesSnapshot({
    required this.savedAt,
    required this.visitStates,
    required this.ranks,
    this.firstStampAt,
    this.exploredAt = const {},
    this.checkIns = CheckInsOverview.none,
  });

  final DateTime savedAt;
  final Map<int, String> visitStates;
  final Map<int, String> ranks;
  final DateTime? firstStampAt;

  /// When each explored county was confirmed, by county code.
  final Map<int, DateTime> exploredAt;
  final CheckInsOverview checkIns;
}

class BadgesSnapshotStore {
  const BadgesSnapshotStore();

  static String _key(String userId) => 'badges.snapshot.$userId';

  Future<BadgesSnapshot?> read(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key(userId));
      if (raw == null) return null;
      final json = jsonDecode(raw);
      if (json is! Map) return null;
      final savedAt = DateTime.tryParse('${json['saved_at']}');
      if (savedAt == null) return null;
      return BadgesSnapshot(
        savedAt: savedAt,
        visitStates: _ints(json['visits']),
        ranks: _ints(json['ranks']),
        firstStampAt: DateTime.tryParse('${json['first_stamp_at']}'),
        exploredAt: _dates(json['explored_at']),
        checkIns: CheckInsOverview.fromJson(json['check_ins']),
      );
    } on Object {
      return null;
    }
  }

  Future<void> write(
    String userId, {
    required Map<int, String> visitStates,
    required Map<int, String> ranks,
    required DateTime now,
    DateTime? firstStampAt,
    Map<int, DateTime> exploredAt = const {},
    CheckInsOverview checkIns = CheckInsOverview.none,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _key(userId),
        jsonEncode({
          'saved_at': now.toUtc().toIso8601String(),
          'visits': {for (final e in visitStates.entries) '${e.key}': e.value},
          'ranks': {for (final e in ranks.entries) '${e.key}': e.value},
          if (firstStampAt != null)
            'first_stamp_at': firstStampAt.toUtc().toIso8601String(),
          'explored_at': {
            for (final e in exploredAt.entries)
              '${e.key}': e.value.toUtc().toIso8601String(),
          },
          'check_ins': checkIns.toJson(),
        }),
      );
    } on Object {
      // A saved copy is a convenience; never fail the live load over it.
    }
  }

  static Map<int, DateTime> _dates(Object? raw) => {
    if (raw is Map)
      for (final e in raw.entries)
        if (int.tryParse('${e.key}') case final int code)
          if (DateTime.tryParse('${e.value}') case final DateTime date)
            code: date,
  };

  static Map<int, String> _ints(Object? raw) => {
    if (raw is Map)
      for (final e in raw.entries)
        if (int.tryParse('${e.key}') != null && e.value is String)
          int.parse('${e.key}'): e.value as String,
  };
}
