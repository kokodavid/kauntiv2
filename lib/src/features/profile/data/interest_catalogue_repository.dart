import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/place_interest.dart';

/// The interests an admin has switched on, from the `interests` table
/// (readable by any signed-in user). The last good answer is kept on this
/// phone so a launch without a connection still shows the real list.
class InterestCatalogueRepository {
  const InterestCatalogueRepository(this.client);

  final SupabaseClient client;

  static const _timeout = Duration(seconds: 8);
  static const _prefsKey = 'profile.interest_catalogue';

  /// The list from the server, remembered on this phone. Empty when the
  /// table is missing or has no active rows.
  Future<List<PlaceInterest>> fetch() async {
    final rows = await client
        .from('interests')
        .select('key, label, short_name, icon_name, icon_url, sort_order')
        .eq('active', true)
        .order('sort_order')
        .timeout(_timeout);
    final list = parse(rows);
    if (list.isNotEmpty) await _remember(rows);
    return list;
  }

  /// The list remembered on this phone, or empty.
  Future<List<PlaceInterest>> cached() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefsKey);
      if (raw == null) return const [];
      return parse((jsonDecode(raw) as List).cast<Map<dynamic, dynamic>>());
    } on Object {
      return const [];
    }
  }

  Future<void> _remember(List<Map<String, dynamic>> rows) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, jsonEncode(rows));
    } on Object {
      // Only a speed-up.
    }
  }

  /// Rows to interests: blank keys skipped, repeats dropped, ordered by
  /// `sort_order` then label.
  static List<PlaceInterest> parse(Iterable<Map<dynamic, dynamic>> rows) {
    final seen = <String>{};
    final list = <PlaceInterest>[
      for (final row in rows)
        if ('${row['key']}'.trim().isNotEmpty &&
            seen.add('${row['key']}'.trim()))
          PlaceInterest.fromRow(row),
    ];
    return list..sort((a, b) {
      final byOrder = a.sortOrder.compareTo(b.sortOrder);
      return byOrder != 0 ? byOrder : a.label.compareTo(b.label);
    });
  }

  /// Codes of the coastal counties (`counties.is_coastal`).
  Future<Set<int>> coastalCountyCodes() async {
    final rows = await client
        .from('counties')
        .select('id')
        .eq('is_coastal', true)
        .timeout(_timeout);
    return {for (final row in rows) (row['id'] as num).toInt()};
  }
}
