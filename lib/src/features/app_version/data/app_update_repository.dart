import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../domain/app_update_policy.dart';
import '../domain/semantic_version.dart';

class AppUpdateRepository {
  const AppUpdateRepository(this._client, this._channel);

  final SupabaseClient? _client;
  final String _channel;

  String get _dismissedVersionKey => 'app_update_dismissed_$_channel';

  Future<AppUpdatePolicy?> check() async {
    final client = _client;
    if (client == null) return null;
    final package = await PackageInfo.fromPlatform().timeout(
      const Duration(seconds: 2),
    );
    final current = SemanticVersion.tryParse(package.version);
    if (current == null) return null;
    final platform = switch (defaultTargetPlatform) {
      TargetPlatform.iOS => 'ios',
      TargetPlatform.android => 'android',
      _ => null,
    };
    if (platform == null) return null;
    final response = await client
        .rpc<Map<String, dynamic>>(
          'get_app_update_policy',
          params: {
            'p_platform': platform,
            'p_channel': _channel,
            'p_current_version': current.toString(),
          },
        )
        .timeout(const Duration(seconds: 3));
    return AppUpdatePolicy.fromJson(response, current);
  }

  String get _snoozedAtKey => 'app_update_snoozed_at_$_channel';

  /// True while a soft prompt for [version] was dismissed within [snooze].
  Future<bool> isSoftSnoozed(String version, Duration snooze) async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getString(_dismissedVersionKey) != version) return false;
    final at = prefs.getInt(_snoozedAtKey);
    if (at == null) return false;
    final age = DateTime.now().millisecondsSinceEpoch - at;
    return age < snooze.inMilliseconds;
  }

  Future<void> snoozeSoft(String version) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_dismissedVersionKey, version);
    await prefs.setInt(_snoozedAtKey, DateTime.now().millisecondsSinceEpoch);
  }

  Future<bool> openStore(Uri? uri) async {
    if (uri == null) return false;
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } on Object {
      return false;
    }
  }
}
