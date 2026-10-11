import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/public_profile.dart';
import '../domain/trip_stats.dart';

/// The last name / handle / photo and Trip stats that loaded, kept on the
/// phone (one per account) so Profile still shows them without a
/// connection.
class ProfileSnapshotStore {
  const ProfileSnapshotStore();

  static String _key(String userId) => 'profile.snapshot.$userId';

  Future<PublicProfile?> readProfile(String userId) async {
    final json = await _read(userId);
    final raw = json?['profile'];
    if (raw is! Map) return null;
    final name = raw['display_name'];
    final handle = raw['handle'];
    if (name is! String || handle is! String) return null;
    final avatar = raw['avatar_url'];
    return PublicProfile(
      displayName: name,
      handle: handle,
      avatarUrl: avatar is String ? avatar : null,
    );
  }

  Future<TripStats?> readStats(String userId) async {
    final json = await _read(userId);
    final raw = json?['stats'];
    if (raw is! Map) return null;
    final count = raw['trip_count'];
    final total = raw['total_m'];
    final longest = raw['longest_m'];
    if (count is! num || total is! num || longest is! num) return null;
    return TripStats(
      tripCount: count.toInt(),
      totalDistanceM: total.toDouble(),
      longestDistanceM: longest.toDouble(),
    );
  }

  /// When either half was last saved; null when nothing is.
  Future<DateTime?> savedAt(String userId) async {
    final json = await _read(userId);
    return DateTime.tryParse('${json?['saved_at']}');
  }

  Future<void> writeProfile(
    String userId,
    PublicProfile profile,
    DateTime now,
  ) => _merge(userId, now, {
    'profile': {
      'display_name': profile.displayName,
      'handle': profile.handle,
      'avatar_url': profile.avatarUrl,
    },
  });

  Future<void> writeStats(String userId, TripStats stats, DateTime now) =>
      _merge(userId, now, {
        'stats': {
          'trip_count': stats.tripCount,
          'total_m': stats.totalDistanceM,
          'longest_m': stats.longestDistanceM,
        },
      });

  Future<Map<String, dynamic>?> _read(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key(userId));
      if (raw == null) return null;
      final json = jsonDecode(raw);
      return json is Map<String, dynamic> ? json : null;
    } on Object {
      return null;
    }
  }

  Future<void> _merge(
    String userId,
    DateTime now,
    Map<String, dynamic> part,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final current = await _read(userId) ?? <String, dynamic>{};
      await prefs.setString(
        _key(userId),
        jsonEncode({
          ...current,
          ...part,
          'saved_at': now.toUtc().toIso8601String(),
        }),
      );
    } on Object {
      // A saved copy is a convenience; never fail the live load over it.
    }
  }
}
