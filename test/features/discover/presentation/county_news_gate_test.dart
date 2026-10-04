import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaunti47_v2/src/features/discover/presentation/county_news_gate.dart';

void main() {
  testWidgets('keeps news hidden while the remote flag is resolving', (
    tester,
  ) async {
    final enabled = Completer<bool>();
    await tester.pumpWidget(
      MaterialApp(
        home: CountyNewsGate(
          enabled: enabled.future,
          builder: (_) => const Text('In the news'),
        ),
      ),
    );

    expect(find.text('In the news'), findsNothing);

    enabled.complete(false);
    await tester.pumpAndSettle();
    expect(find.text('In the news'), findsNothing);
  });

  testWidgets('shows news only after the flag resolves enabled', (tester) async {
    final enabled = Completer<bool>();
    await tester.pumpWidget(
      MaterialApp(
        home: CountyNewsGate(
          enabled: enabled.future,
          builder: (_) => const Text('In the news'),
        ),
      ),
    );
    expect(find.text('In the news'), findsNothing);

    enabled.complete(true);
    await tester.pumpAndSettle();
    expect(find.text('In the news'), findsOneWidget);
  });
}
