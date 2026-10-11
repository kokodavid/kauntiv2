import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaunti47_v2/src/core/domain/connectivity_state.dart';
import 'package:kaunti47_v2/src/core/services/connectivity_provider.dart';
import 'package:kaunti47_v2/src/core/services/fail_fast.dart';

class _Controllable extends Connectivity {
  _Controllable(this._first);
  final ConnectivityStatus _first;

  @override
  ConnectivityState build() => ConnectivityState(status: _first);

  void go(ConnectivityStatus status) =>
      state = ConnectivityState(status: status);
}

void main() {
  late _Controllable connectivity;

  ProviderContainer makeContainer(ConnectivityStatus first) {
    connectivity = _Controllable(first);
    final container = ProviderContainer(
      overrides: [connectivityProvider.overrideWith(() => connectivity)],
    );
    addTearDown(container.dispose);
    return container;
  }

  test('offline: refuses at once without calling the server', () async {
    final container = makeContainer(ConnectivityStatus.offline);
    final result = Provider<Future<int>>(
      (ref) => failFast(ref, () async => fail('should not be called')),
    );
    await expectLater(
      container.read(result),
      throwsA(isA<OfflineException>()),
    );
  });

  test('online: returns the result', () async {
    final container = makeContainer(ConnectivityStatus.online);
    final result = Provider<Future<int>>((ref) => failFast(ref, () async => 7));
    expect(await container.read(result), 7);
  });

  test('goes offline mid-load: gives up straight away', () async {
    final container = makeContainer(ConnectivityStatus.online);
    final never = Completer<int>();
    final result = Provider<Future<int>>(
      (ref) => failFast(ref, () => never.future),
    );
    final future = container.read(result);
    final expectation = expectLater(future, throwsA(isA<OfflineException>()));
    container.read(connectivityProvider);
    connectivity.go(ConnectivityStatus.offline);
    await expectation;
  });
}
