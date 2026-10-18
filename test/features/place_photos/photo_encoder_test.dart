import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:kaunti47_v2/src/features/place_photos/application/photo_encoder.dart';
import 'package:kaunti47_v2/src/features/place_photos/domain/encoded_photo.dart';

Uint8List _jpeg(int w, int h) =>
    Uint8List.fromList(img.encodeJpg(img.Image(width: w, height: h)));

void main() {
  test('large photo is shrunk to 1600 px with a 480 px thumbnail', () {
    final out = encodePhotoSync(_jpeg(3200, 2400));
    expect(out.width, 1600);
    expect(out.height, 1200);
    expect(img.decodeJpg(out.thumb)!.width, 480);
    expect(out.hash, hasLength(64));
  });

  test('small photo is not enlarged', () {
    final out = encodePhotoSync(_jpeg(1000, 900));
    expect((out.width, out.height), (1000, 900));
  });

  test('same picture hashes the same, a different one does not', () {
    final a = encodePhotoSync(_jpeg(900, 900));
    expect(encodePhotoSync(_jpeg(900, 900)).hash, a.hash);
    expect(encodePhotoSync(_jpeg(901, 900)).hash, isNot(a.hash));
  });

  test('bytes that are not a picture are refused', () {
    expect(
      () => encodePhotoSync(Uint8List.fromList([1, 2, 3])),
      throwsA(isA<UnreadablePhoto>()),
    );
  });
}
