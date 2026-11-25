import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:kaunti47_v2/src/features/journeys/data/fix_tapping_location_source.dart';
import 'package:kaunti47_v2/src/features/journeys/domain/journey_fix.dart';
import 'package:kaunti47_v2/src/features/journeys/domain/journey_transport_mode.dart';

class _Source implements JourneyLocationSource {
  // Closed by each test's teardown (or explicitly before the test completes).
  // ignore: close_sinks
  final controller = StreamController<JourneyFix>();
  var started = 0;

  @override
  Stream<JourneyFix> get fixes => controller.stream;

  @override
  Future<void> ensureAvailable() async {}

  @override
  Future<void> start({JourneyTransportMode? mode}) async => started++;

  @override
  Future<void> stop() async {}
}

JourneyFix _fix() => JourneyFix(
  recordedAt: DateTime.utc(2026, 11, 13, 5),
  latitude: -1.29,
  longitude: 36.86,
  accuracyMeters: 10,
);

void main() {
  test('every fix reaches the tap and still passes through', () async {
    final inner = _Source();
    addTearDown(() async {
      if (!inner.controller.isClosed) await inner.controller.close();
    });
    final tapped = <JourneyFix>[];
    final source = FixTappingLocationSource(inner, tapped.add);
    final received = <JourneyFix>[];
    final sub = source.fixes.listen(received.add);

    final fix = _fix();
    inner.controller.add(fix);
    await Future<void>.delayed(Duration.zero);

    expect(received, [fix]);
    expect(tapped, [fix]);
    await sub.cancel();
    await inner.controller.close();
  });

  test('a failing tap never breaks the recording', () async {
    final inner = _Source();
    addTearDown(() async {
      if (!inner.controller.isClosed) await inner.controller.close();
    });
    final source = FixTappingLocationSource(
      inner,
      (_) => throw StateError('x'),
    );
    final received = <JourneyFix>[];
    final sub = source.fixes.listen(received.add);

    inner.controller.add(_fix());
    await Future<void>.delayed(Duration.zero);

    expect(received, hasLength(1));
    await sub.cancel();
    await inner.controller.close();
  });

  test('start is passed to the wrapped source', () async {
    final inner = _Source();
    addTearDown(() async {
      if (!inner.controller.isClosed) await inner.controller.close();
    });
    await FixTappingLocationSource(inner, (_) {}).start();
    expect(inner.started, 1);
    await inner.controller.close();
  });
}
