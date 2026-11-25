import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaunti47_v2/src/features/trip_plans/presentation/plan_date_picker_sheet.dart';

void main() {
  DateTime? result;
  var closed = false;

  setUp(() {
    result = null;
    closed = false;
  });

  Future<void> open(WidgetTester tester, {DateTime? selected}) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                result = await showPlanDateSheet(
                  context,
                  title: 'Start date',
                  first: DateTime(2026, 10, 30),
                  last: DateTime(2028, 10, 29),
                  selected: selected,
                );
                closed = true;
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  testWidgets('shows the first month; earlier days are not pickable', (
    tester,
  ) async {
    await open(tester);
    expect(find.text('Start date'), findsOneWidget);
    expect(find.text('October 2026'), findsOneWidget);
    expect(find.text('Pick a day'), findsOneWidget);

    await tester.tap(find.text('29'));
    await tester.pump();
    expect(find.text('Pick a day'), findsOneWidget);
  });

  testWidgets('picking a day and confirming returns it', (tester) async {
    await open(tester);
    await tester.tap(find.text('31'));
    await tester.pump();
    expect(find.text('Set Sat 31 Oct'), findsOneWidget);
    await tester.tap(find.text('Set Sat 31 Oct'));
    await tester.pumpAndSettle();
    expect(result, DateTime(2026, 10, 31));
  });

  testWidgets('the next-month arrow moves on; the back arrow stops at the '
      'first month', (tester) async {
    await open(tester);
    final previous = tester.widget<IconButton>(
      find.widgetWithIcon(IconButton, Icons.chevron_left),
    );
    expect(previous.onPressed, isNull);

    await tester.tap(find.byTooltip('Next month'));
    await tester.pumpAndSettle();
    expect(find.text('November 2026'), findsOneWidget);
    await tester.tap(find.text('14'));
    await tester.pump();
    await tester.tap(find.text('Set Sat 14 Nov'));
    await tester.pumpAndSettle();
    expect(result, DateTime(2026, 11, 14));
  });

  testWidgets('opens on the month of the date already chosen', (tester) async {
    await open(tester, selected: DateTime(2026, 12, 11));
    expect(find.text('December 2026'), findsOneWidget);
    expect(find.text('Set Fri 11 Dec'), findsOneWidget);
  });

  testWidgets('closing without a choice returns nothing', (tester) async {
    await open(tester);
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();
    expect(closed, isTrue);
    expect(result, isNull);
  });
}
