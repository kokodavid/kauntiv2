import 'dart:io';
import 'dart:ui';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../domain/feedback_models.dart';

/// Reads what the app can tell about itself and the phone, so a report
/// arrives with version, device and screen already filled in.
class FeedbackContextSource {
  const FeedbackContextSource();

  Future<FeedbackContext> capture({String? screen, String? flavor}) async {
    String? version;
    String? build;
    try {
      final info = await PackageInfo.fromPlatform();
      version = info.version;
      build = info.buildNumber;
    } on Object {
      // Missing app info must never block a report.
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
      // Same: the report goes without device details.
    }
    return FeedbackContext(
      screen: screen,
      appVersion: version,
      buildNumber: build,
      flavor: flavor,
      platform: Platform.isAndroid
          ? 'android'
          : Platform.isIOS
          ? 'ios'
          : Platform.operatingSystem,
      osVersion: os,
      deviceModel: model,
      locale: PlatformDispatcher.instance.locale.toLanguageTag(),
      capturedAt: DateTime.now(),
    );
  }
}
