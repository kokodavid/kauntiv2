import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:kaunti47_v2/src/features/map_home/presentation/real_map_sheet_guard.dart';

void main() {
  test('a second tap while a sheet is opening or showing is ignored', () async {
    final guard = RealMapSheetGuard();
    final closed = Completer<void>();
    var opened = 0;

    final first = guard.run(() async {
      opened++;
      await closed.future;
    });
    await guard.run(() async => opened++);
    expect(opened, 1);
    expect(guard.isBusy, isTrue);

    closed.complete();
    await first;
    expect(guard.isBusy, isFalse);

    await guard.run(() async => opened++);
    expect(opened, 2);
  });

  test('the guard reopens even when opening throws', () async {
    final guard = RealMapSheetGuard();
    await expectLater(
      guard.run(() async => throw StateError('no sheet')),
      throwsStateError,
    );
    expect(guard.isBusy, isFalse);
  });
}
