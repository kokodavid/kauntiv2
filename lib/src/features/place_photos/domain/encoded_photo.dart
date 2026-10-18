import 'dart:typed_data';

/// A picked photo ready to upload: the re-encoded copy, its thumbnail and
/// the SHA-256 of the copy (the server uses it to spot repeats).
class EncodedPhoto {
  const EncodedPhoto({
    required this.full,
    required this.thumb,
    required this.width,
    required this.height,
    required this.hash,
  });

  final Uint8List full;
  final Uint8List thumb;
  final int width;
  final int height;
  final String hash;
}

/// The picked file could not be read as a picture.
class UnreadablePhoto implements Exception {
  const UnreadablePhoto();
}
