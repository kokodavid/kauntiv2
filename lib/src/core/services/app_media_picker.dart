import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';

enum AppImageSource { camera, gallery }

class AppPickedImage {
  const AppPickedImage(this._file);

  final XFile _file;

  String get path => _file.path;

  Future<Uint8List> readAsBytes() => _file.readAsBytes();
}

abstract final class AppMediaPicker {
  static Future<AppPickedImage?> pickImage({
    required AppImageSource source,
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
  }) async {
    final file = await ImagePicker().pickImage(
      source: switch (source) {
        AppImageSource.camera => ImageSource.camera,
        AppImageSource.gallery => ImageSource.gallery,
      },
      maxWidth: maxWidth,
      maxHeight: maxHeight,
      imageQuality: imageQuality,
    );
    return file == null ? null : AppPickedImage(file);
  }

  static Future<List<AppPickedImage>> pickMultiImage({
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
  }) async {
    final files = await ImagePicker().pickMultiImage(
      maxWidth: maxWidth,
      maxHeight: maxHeight,
      imageQuality: imageQuality,
    );
    return [for (final file in files) AppPickedImage(file)];
  }
}
