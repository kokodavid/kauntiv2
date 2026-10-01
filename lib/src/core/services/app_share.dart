import 'dart:typed_data';
import 'dart:ui';

import 'package:share_plus/share_plus.dart';

/// Hands content to the phone's share sheet (Instagram, WhatsApp, X...).
abstract final class AppShare {
  /// Shares a PNG image with an optional caption. [origin] anchors the
  /// share popover on iPad.
  static Future<void> image(
    Uint8List png, {
    required String fileName,
    String? text,
    Rect? origin,
  }) async {
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile.fromData(png, mimeType: 'image/png', name: fileName)],
        fileNameOverrides: [fileName],
        text: text,
        sharePositionOrigin: origin,
      ),
    );
  }
}
