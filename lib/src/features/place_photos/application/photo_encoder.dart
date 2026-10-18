import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

import '../domain/encoded_photo.dart';

const _fullEdge = 1600;
const _thumbEdge = 480;

/// Re-encodes [source] as a JPEG of at most 1600 px plus a 480 px
/// thumbnail, off the UI thread. Re-encoding also drops EXIF (location,
/// camera) and applies the photo's rotation.
Future<EncodedPhoto> encodePhoto(Uint8List source) =>
    compute(encodePhotoSync, source);

@visibleForTesting
EncodedPhoto encodePhotoSync(Uint8List source) {
  final decoded = img.decodeImage(source);
  if (decoded == null) throw const UnreadablePhoto();
  final upright = img.bakeOrientation(decoded);
  final full = _fit(upright, _fullEdge);
  final thumb = _fit(full, _thumbEdge);
  final fullBytes = Uint8List.fromList(img.encodeJpg(full, quality: 85));
  return EncodedPhoto(
    full: fullBytes,
    thumb: Uint8List.fromList(img.encodeJpg(thumb, quality: 75)),
    width: full.width,
    height: full.height,
    hash: sha256.convert(fullBytes).toString(),
  );
}

img.Image _fit(img.Image image, int edge) {
  if (image.width <= edge && image.height <= edge) return image;
  return image.width >= image.height
      ? img.copyResize(image, width: edge)
      : img.copyResize(image, height: edge);
}
