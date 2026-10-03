import 'dart:io';

import 'package:flutter/services.dart';

/// Shares straight into Instagram's Stories composer - skipping the
/// system share sheet in [AppShare] entirely - via the iOS-only
/// `com.giglab.kaunti47/instagram_stories` channel (`AppDelegate.swift`
/// + `InstagramStoriesShare.swift`). Instagram has no public SDK for
/// this: the native side writes the image to the pasteboard under
/// Instagram's own reserved keys, then opens `instagram-stories://share`,
/// which Instagram reads the image back from the instant it opens.
///
/// Android has no equivalent contract, so [isAvailable] is always false
/// there - TikTok's own Stories integration is a separate, larger piece
/// of work (its own SDK and developer registration) not covered here.
abstract final class AppInstagramStories {
  static const _channel = MethodChannel(
    'com.giglab.kaunti47/instagram_stories',
  );

  /// Whether Instagram is installed and able to accept a Stories share.
  /// Cheap enough to call from `build()`/`initState` to decide whether
  /// to show the button at all.
  static Future<bool> isAvailable() async {
    if (!Platform.isIOS) return false;
    try {
      return await _channel.invokeMethod<bool>('isAvailable') ?? false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  /// Opens Instagram with [image] (PNG bytes) pre-loaded as the Story's
  /// background. [backgroundTopColor]/[backgroundBottomColor] (hex
  /// strings, e.g. `'#F5F5F5'`) are what Instagram fills in behind the
  /// image if it doesn't cover the full Story frame; [attributionLink]
  /// becomes a tappable link sticker on the posted Story. Returns
  /// whether Instagram actually opened - false (never an exception) if
  /// it's not installed or declines the handoff.
  static Future<bool> share(
    Uint8List image, {
    String? backgroundTopColor,
    String? backgroundBottomColor,
    String? attributionLink,
  }) async {
    if (!Platform.isIOS) return false;
    try {
      return await _channel.invokeMethod<bool>('share', {
            'image': image,
            'backgroundTopColor': ?backgroundTopColor,
            'backgroundBottomColor': ?backgroundBottomColor,
            'attributionLink': ?attributionLink,
          }) ??
          false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }
}
