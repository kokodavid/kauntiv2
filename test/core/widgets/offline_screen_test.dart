import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaunti47_v2/src/core/domain/connectivity_state.dart';
import 'package:kaunti47_v2/src/core/services/connectivity_provider.dart';
import 'package:kaunti47_v2/src/core/services/offline_screen_presence.dart';
import 'package:kaunti47_v2/src/core/widgets/offline_screen.dart';

class _Fixed extends Connectivity {
  _Fixed(this._status);
  final ConnectivityStatus _status;

  @override
  ConnectivityState build() => ConnectivityState(status: _status);

  @override
  Future<void> recheck() async {}
}

Widget _app(ConnectivityStatus status, VoidCallback onRetry) => ProviderScope(
  overrides: [connectivityProvider.overrideWith(() => _Fixed(status))],
  child: MaterialApp(
    home: Scaffold(body: OfflineScreen(onRetry: onRetry)),
  ),
);

void main() {
  testWidgets('offline: says so, offers Try again, and hides the banner', (
    tester,
  ) async {
    var retried = 0;
    await tester.pumpWidget(_app(ConnectivityStatus.offline, () => retried++));
    await tester.pump();

    expect(find.text("You're offline"), findsOneWidget);
    expect(find.text('Counties you visit are still saved.'), findsOneWidget);
    final container = ProviderScope.containerOf(
      tester.element(find.byType(OfflineScreen)),
    );
    expect(container.read(offlineBannerSuppressedProvider), isTrue);

    await tester.tap(find.text('Try again'));
    await tester.pump();
    expect(retried, 1);
  });

  testWidgets('online but failed: the server-error copy', (tester) async {
    await tester.pumpWidget(_app(ConnectivityStatus.online, () {}));
    await tester.pump();

    expect(find.text("Couldn't load this page"), findsOneWidget);
    expect(find.text("You're offline"), findsNothing);
    expect(find.text('Counties you visit are still saved.'), findsNothing);
  });

  testWidgets('leaving the screen lifts the banner suppression', (
    tester,
  ) async {
    // Own the container: a ProviderScope disposes its own when it leaves
    // the tree, which would take the presence provider with it.
    final container = ProviderContainer(
      overrides: [
        connectivityProvider.overrideWith(
          () => _Fixed(ConnectivityStatus.offline),
        ),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Scaffold(body: OfflineScreen(onRetry: () {})),
        ),
      ),
    );
    await tester.pump();
    expect(container.read(offlineScreenPresenceProvider), 1);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: SizedBox()),
      ),
    );
    await tester.pump();
    expect(container.read(offlineScreenPresenceProvider), 0);
  });
}
