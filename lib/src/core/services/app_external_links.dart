import 'dart:io';

import 'package:url_launcher/url_launcher.dart';

abstract final class AppExternalLinks {
  static String get subscriptionStoreName =>
      Platform.isIOS ? 'App Store' : 'Google Play';

  /// Opens [uri] in another app (the maps app, the browser).
  static Future<bool> open(Uri uri) =>
      launchUrl(uri, mode: LaunchMode.externalApplication);

  static Future<void> manageSubscription() async {
    final uri = Platform.isIOS
        ? Uri.parse('itms-apps://apps.apple.com/account/subscriptions')
        : Uri.parse('https://play.google.com/store/account/subscriptions');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  static Future<void> openPrivacyPolicy() async {
    await launchUrl(
      Uri.parse('https://kaunti47.com/privacy'),
      mode: LaunchMode.externalApplication,
    );
  }
}
