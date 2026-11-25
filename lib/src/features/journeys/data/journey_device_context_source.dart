import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';

class JourneyDeviceContext {
  const JourneyDeviceContext({
    this.appVersion,
    this.platform,
    this.osVersion,
    this.deviceModel,
  });

  final String? appVersion;
  final String? platform;
  final String? osVersion;
  final String? deviceModel;
}

/// Captures the small device snapshot stored with Trip quality diagnostics.
class JourneyDeviceContextSource {
  const JourneyDeviceContextSource();

  Future<JourneyDeviceContext> capture() async {
    String? version;
    try {
      version = (await PackageInfo.fromPlatform()).version;
    } on Object {
      // Diagnostics remain useful without app metadata.
    }

    String? os;
    String? model;
    try {
      final plugin = DeviceInfoPlugin();
      if (Platform.isAndroid) {
        final info = await plugin.androidInfo;
        os = 'Android ${info.version.release} (API ${info.version.sdkInt})';
        model = '${info.manufacturer} ${info.model}'.trim();
      } else if (Platform.isIOS) {
        final info = await plugin.iosInfo;
        os = '${info.systemName} ${info.systemVersion}';
        model = info.utsname.machine;
      }
    } on Object {
      // A device-info failure must not block quality upload.
    }

    return JourneyDeviceContext(
      appVersion: version,
      platform: Platform.isAndroid
          ? 'android'
          : Platform.isIOS
          ? 'ios'
          : Platform.operatingSystem,
      osVersion: os,
      deviceModel: model,
    );
  }
}
