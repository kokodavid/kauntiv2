import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Which plans have an offline copy on this phone, and since when.
class PlanOfflineStore {
  const PlanOfflineStore();

  static String _key(String userId, String planId) =>
      'trip_plans.offline.$userId.$planId';

  Future<DateTime?> savedAt(String userId, String planId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return DateTime.tryParse(prefs.getString(_key(userId, planId)) ?? '');
    } on Object {
      return null;
    }
  }

  Future<void> markSaved(String userId, String planId, DateTime at) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key(userId, planId), at.toIso8601String());
    } on Object {
      // The copy still works; the menu just won't remember it.
    }
  }

  Future<void> clear(String userId, String planId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_key(userId, planId));
    } on Object {
      // Nothing to clean up.
    }
  }
}

/// Fetches place pictures into the image cache so they show without signal.
class PlanOfflineImages {
  const PlanOfflineImages();

  Future<void> prefetch(Iterable<String> urls) async {
    final manager = DefaultCacheManager();
    for (final url in urls.toSet()) {
      try {
        await manager.getSingleFile(url);
      } on Object {
        // A missing picture shows its placeholder, as it does today.
      }
    }
  }
}
