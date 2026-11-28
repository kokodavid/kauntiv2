import 'dart:io' show Platform;

import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Which phone and build a health report is about. Make and model are what
/// lets the team see that one maker's phones keep dropping out.
class DeviceProfile {
  const DeviceProfile({
    required this.platform,
    this.osVersion,
    this.manufacturer,
    this.model,
    this.appVersion,
  });

  final String platform;
  final String? osVersion;
  final String? manufacturer;
  final String? model;
  final String? appVersion;

  static DeviceProfile? _cached;

  static Future<DeviceProfile> load() async {
    final cached = _cached;
    if (cached != null) return cached;
    final platform = Platform.isIOS ? 'ios' : 'android';
    String? os;
    String? maker;
    String? model;
    String? app;
    try {
      final info = DeviceInfoPlugin();
      if (Platform.isIOS) {
        final ios = await info.iosInfo;
        os = ios.systemVersion;
        maker = 'Apple';
        model = ios.utsname.machine;
      } else {
        final android = await info.androidInfo;
        os = android.version.release;
        maker = android.manufacturer;
        model = android.model;
      }
      final pkg = await PackageInfo.fromPlatform();
      app = '${pkg.version}+${pkg.buildNumber}';
    } on Object {
      // Partial details still make a useful report.
    }
    return _cached = DeviceProfile(
      platform: platform,
      osVersion: os,
      manufacturer: maker,
      model: model,
      appVersion: app,
    );
  }
}
