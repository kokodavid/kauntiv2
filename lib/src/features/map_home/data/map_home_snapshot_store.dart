import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/map_home_snapshot.dart';

/// Keeps Home's last good [MapHomeSnapshot] on this phone, one per account
/// so a second account never sees the first one's counties.
class MapHomeSnapshotStore {
  const MapHomeSnapshotStore();

  static String _key(String userId) => 'map_home.snapshot.$userId';

  Future<MapHomeSnapshot?> read(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key(userId));
      if (raw == null) return null;
      return MapHomeSnapshot.fromJson(jsonDecode(raw));
    } on Object {
      return null;
    }
  }

  Future<void> write(String userId, MapHomeSnapshot snapshot) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key(userId), jsonEncode(snapshot.toJson()));
    } on Object {
      // A snapshot is a convenience; failing to save it must not break Home.
    }
  }
}
