import 'package:flutter_test/flutter_test.dart';
import 'package:kaunti47_v2/src/core/services/camera_roll_matcher.dart';
import 'package:photo_manager/photo_manager.dart';

CameraRollMatch _shot(
  String id,
  DateTime at, {
  List<CameraRollMatch> burst = const [],
}) => CameraRollMatch(
  asset: AssetEntity(id: id, typeInt: 1, width: 1, height: 1),
  capturedAt: at,
  alternates: burst,
);

void main() {
  final noon = DateTime.utc(2026, 10, 15, 12);

  test('a cluster with a shot already on the Trip is dropped whole', () {
    final burst = _shot(
      'a',
      noon,
      burst: [
        _shot('b', noon.add(const Duration(seconds: 1))),
        _shot('c', noon.add(const Duration(seconds: 2))),
      ],
    );
    final other = _shot('z', noon.add(const Duration(minutes: 20)));
    // Frame "b" was uploaded earlier: the burst is done, "z" is still new.
    final left = CameraRollMatcher.withoutAdded(
      [burst, other],
      [noon.add(const Duration(seconds: 1))],
    );
    expect(left.map((m) => m.asset.id), ['z']);
  });

  test('nothing added means nothing dropped', () {
    final left = CameraRollMatcher.withoutAdded([_shot('a', noon)], const []);
    expect(left, hasLength(1));
  });

  test('adding one frame removes its whole burst by asset id', () {
    final burst = _shot('a', noon, burst: [_shot('b', noon)]);
    final other = _shot('z', noon.add(const Duration(minutes: 20)));
    final left = CameraRollMatcher.withoutAssets([burst, other], {'b'});
    expect(left.map((m) => m.asset.id), ['z']);
  });
}
