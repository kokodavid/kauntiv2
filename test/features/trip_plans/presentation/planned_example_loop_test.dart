import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaunti47_v2/src/features/trip_plans/presentation/planned_example_loop.dart';

Widget _app({bool reduceMotion = false}) => MaterialApp(
  home: MediaQuery(
    data: MediaQueryData(disableAnimations: reduceMotion),
    child: const Scaffold(body: PlannedExampleLoop()),
  ),
);

void main() {
  testWidgets('cycles Day 1, 2, 3 and back to Day 1', (tester) async {
    await tester.pumpWidget(_app());
    expect(find.text('Mombasa day'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 4000));
    await tester.pump(const Duration(milliseconds: 1100));
    expect(find.text('Coast drive north'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 4000));
    await tester.pump(const Duration(milliseconds: 1100));
    expect(find.text('To Lamu'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 4000));
    await tester.pump(const Duration(milliseconds: 1100));
    expect(find.text('Mombasa day'), findsOneWidget);
  });

  testWidgets('a tap pauses it and a second tap resumes', (tester) async {
    await tester.pumpWidget(_app());
    await tester.tap(find.byType(PlannedExampleLoop));
    await tester.pump(const Duration(milliseconds: 4000));
    await tester.pump(const Duration(milliseconds: 1100));
    expect(find.text('Mombasa day'), findsOneWidget);

    await tester.tap(find.byType(PlannedExampleLoop));
    await tester.pump(const Duration(milliseconds: 4000));
    await tester.pump(const Duration(milliseconds: 1100));
    expect(find.text('Coast drive north'), findsOneWidget);
  });

  testWidgets('reduced motion shows Day 1 only', (tester) async {
    await tester.pumpWidget(_app(reduceMotion: true));
    await tester.pump(const Duration(seconds: 10));
    expect(find.text('Mombasa day'), findsOneWidget);
    expect(find.text('Coast drive north'), findsNothing);
  });

  testWidgets('the whole day card is labelled for screen readers', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(_app());
    expect(find.bySemanticsLabel('Example plan, day 1 of 3'), findsOneWidget);
    handle.dispose();
  });
}
