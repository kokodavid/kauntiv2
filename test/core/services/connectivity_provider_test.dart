import 'package:fake_async/fake_async.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaunti47_v2/src/core/domain/connectivity_state.dart';
import 'package:kaunti47_v2/src/core/services/connectivity_probe.dart';
import 'package:kaunti47_v2/src/core/services/connectivity_provider.dart';

class _Probe extends ConnectivityProbe {
  _Probe() : super('example.test');
  bool up = true;

  @override
  Future<bool> reachable() async => up;
}

void main() {
  test('goes offline after a confirmed failure, then reconnects', () {
    fakeAsync((async) {
      final probe = _Probe();
      final container = ProviderContainer(
        overrides: [connectivityProbeProvider.overrideWithValue(probe)],
      );
      addTearDown(container.dispose);
      ConnectivityStatus status() =>
          container.read(connectivityProvider).status;

      container.listen(connectivityProvider, (_, _) {});
      async.flushMicrotasks();
      expect(status(), ConnectivityStatus.online);

      probe.up = false;
      async.elapse(Connectivity.onlineEvery);
      // The failure is confirmed 1.5 s later, not at once.
      expect(status(), ConnectivityStatus.online);
      async.elapse(Connectivity.confirmAfter);
      expect(status(), ConnectivityStatus.offline);

      probe.up = true;
      async.elapse(Connectivity.offlineEvery);
      expect(status(), ConnectivityStatus.reconnecting);

      container.read(connectivityProvider.notifier).markSynced();
      expect(status(), ConnectivityStatus.upToDate);
      async.elapse(Connectivity.upToDateFor);
      expect(status(), ConnectivityStatus.online);
    });
  });

  test('a stalled catch-up still finishes after the cap', () {
    fakeAsync((async) {
      final probe = _Probe()..up = false;
      final container = ProviderContainer(
        overrides: [connectivityProbeProvider.overrideWithValue(probe)],
      );
      addTearDown(container.dispose);
      container.listen(connectivityProvider, (_, _) {});
      async.elapse(Connectivity.confirmAfter + const Duration(seconds: 1));
      expect(
        container.read(connectivityProvider).status,
        ConnectivityStatus.offline,
      );
      probe.up = true;
      async.elapse(Connectivity.offlineEvery);
      expect(
        container.read(connectivityProvider).status,
        ConnectivityStatus.reconnecting,
      );
      async.elapse(Connectivity.syncCap);
      expect(
        container.read(connectivityProvider).status,
        ConnectivityStatus.upToDate,
      );
    });
  });
}
