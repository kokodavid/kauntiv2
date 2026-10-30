import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaunti47_v2/src/features/trip_plans/domain/plan_day.dart';
import 'package:kaunti47_v2/src/features/trip_plans/domain/plan_place.dart';
import 'package:kaunti47_v2/src/features/trip_plans/presentation/plan_note_sheet.dart';

PlanStop _stop({String? note}) => PlanStop(
  id: 's1',
  note: note,
  place: const PlanPlace(
    id: 'p1',
    name: 'Ragia Waterfalls',
    type: 'waterfall',
    countyCode: 22,
  ),
);

void main() {
  Future<String?> open(WidgetTester tester, {String? note}) async {
    String? result = 'unset';
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async => result = await showPlanNoteSheet(
              context,
              stop: _stop(note: note),
              number: 1,
              color: Colors.indigo,
              dayLabel: 'Day 1',
            ),
            child: const Text('go'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();
    return result;
  }

  testWidgets('shows the stop, and Save note needs some text', (tester) async {
    await open(tester);
    expect(find.text('Note'), findsOneWidget);
    expect(find.text('Ragia Waterfalls'), findsOneWidget);
    expect(find.text('· Day 1'), findsOneWidget);
    expect(find.text('Remove'), findsNothing);
    final save = find.widgetWithText(FilledButton, 'Save note');
    expect(tester.widget<FilledButton>(save).onPressed, isNull);
    await tester.enterText(find.byType(TextField), 'Book ahead');
    await tester.pump();
    expect(tester.widget<FilledButton>(save).onPressed, isNotNull);
  });

  testWidgets('an existing note can be removed', (tester) async {
    await open(tester, note: 'Bring water');
    expect(find.text('Bring water'), findsOneWidget);
    expect(find.text('Remove'), findsOneWidget);
    await tester.tap(find.text('Remove'));
    await tester.pumpAndSettle();
    expect(find.text('Note'), findsNothing);
  });
}
