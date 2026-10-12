import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaunti47_v2/src/core/domain/connectivity_state.dart';
import 'package:kaunti47_v2/src/core/services/connectivity_provider.dart';
import 'package:kaunti47_v2/src/core/widgets/needs_connection.dart';
import 'package:kaunti47_v2/src/core/widgets/saved_chip.dart';

class _Fixed extends Connectivity {
  _Fixed(this._status);
  final ConnectivityStatus _status;

  @override
  ConnectivityState build() => ConnectivityState(status: _status);

  @override
  Future<void> recheck() async {}
}

Widget _app(ConnectivityStatus status, Widget child) => ProviderScope(
  overrides: [connectivityProvider.overrideWith(() => _Fixed(status))],
  child: MaterialApp(home: Scaffold(body: child)),
);

void main() {
  testWidgets('online: renders the section itself', (tester) async {
    await tester.pumpWidget(
      _app(
        ConnectivityStatus.online,
        const NeedsConnection(message: 'x', child: Text('the list')),
      ),
    );
    expect(find.text('the list'), findsOneWidget);
    expect(find.text('Needs a connection'), findsNothing);
  });

  testWidgets('offline: renders the notice with Retry', (tester) async {
    await tester.pumpWidget(
      _app(
        ConnectivityStatus.offline,
        const NeedsConnection(
          message: 'Unclaimed counties load from the internet.',
          child: Text('the list'),
        ),
      ),
    );
    expect(find.text('the list'), findsNothing);
    expect(find.text('Needs a connection'), findsOneWidget);
    expect(
      find.text('Unclaimed counties load from the internet.'),
      findsOneWidget,
    );
    expect(find.text('Retry'), findsOneWidget);
  });

  testWidgets('checking: Retry is disabled and says so', (tester) async {
    await tester.pumpWidget(
      _app(
        ConnectivityStatus.checking,
        const NeedsConnection(child: Text('the list')),
      ),
    );
    expect(find.text('Checking…'), findsOneWidget);
  });

  testWidgets('saved chip only shows while offline', (tester) async {
    final at = DateTime.now().subtract(const Duration(days: 1));
    await tester.pumpWidget(
      _app(ConnectivityStatus.online, SavedChip(savedAt: at)),
    );
    expect(find.text('Saved yesterday'), findsNothing);
    await tester.pumpWidget(
      _app(ConnectivityStatus.offline, SavedChip(savedAt: at)),
    );
    expect(find.text('Saved yesterday'), findsOneWidget);
  });
}
