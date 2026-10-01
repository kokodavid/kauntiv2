import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaunti47_v2/src/app/journey_route_choice_sheet.dart';

void main() {
  testWidgets('Directions only stays visible above floating tab navigation', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    JourneyRouteChoice? choice;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Stack(
            children: [
              Positioned.fill(
                child: Navigator(
                  onGenerateRoute: (_) => MaterialPageRoute<void>(
                    builder: (context) => Center(
                      child: TextButton(
                        onPressed: () async {
                          choice = await JourneyRouteChoiceSheet.show(
                            context,
                            "Machakos People's Park",
                          );
                        },
                        child: const Text('Open route'),
                      ),
                    ),
                  ),
                ),
              ),
              const Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: ColoredBox(
                  color: Colors.black,
                  child: SizedBox(height: 90),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open route'));
    await tester.pumpAndSettle();
    expect(find.text('Directions only').hitTestable(), findsOneWidget);
    await tester.tap(find.text('Directions only'));
    await tester.pumpAndSettle();
    expect(choice, JourneyRouteChoice.directions);
  });
}
