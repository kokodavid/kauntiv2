import 'package:flutter/foundation.dart';

/// "the App Store" on iOS, "Google Play" on Android. Never the channel.
String updateStoreName() => defaultTargetPlatform == TargetPlatform.android
    ? 'Google Play'
    : 'the App Store';

/// Store name for captions that read "Opens ..." (same wording either way).
String updateVersionLabel(Object version) => 'Version $version';
