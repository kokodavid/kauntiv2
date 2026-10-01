import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaunti47_v2/src/core/domain/map_place.dart';
import 'package:kaunti47_v2/src/core/widgets/app_place_sheet.dart';

const _hellsGate = MapPlace(
  id: 'hg',
  name: "Hell's Gate National Park",
  type: 'park',
  countyCode: 32,
  lat: -0.91,
  lng: 36.31,
  summary: 'Gorges, geothermal steam and cycling among zebra.',
);

Future<void> _pump(
  WidgetTester tester, {
  VoidCallback? onOpen,
  Future<bool> Function(String)? onRoute,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: AppPlaceSheet(
          place: _hellsGate,
          onOpen: onOpen,
          onRoute: onRoute,
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('shows the place on its photo card', (tester) async {
    await _pump(tester, onOpen: () {}, onRoute: (_) async => true);
    expect(find.text("Hell's Gate National Park"), findsOneWidget);
    expect(find.text('Nakuru County'), findsOneWidget);
    expect(find.text('Park'), findsOneWidget);
    expect(find.text('Route'), findsOneWidget);
    expect(find.text('View place'), findsOneWidget);
  });

  testWidgets('Route opens directions to the pin', (tester) async {
    final destinations = <String>[];
    await _pump(
      tester,
      onRoute: (destination) async {
        destinations.add(destination);
        return true;
      },
    );
    await tester.tap(find.text('Route'));
    await tester.pump();
    expect(destinations, ['-0.91,36.31']);
    expect(find.text('View place'), findsNothing);
  });

  testWidgets('place route closes the pin sheet before opening the handoff', (
    tester,
  ) async {
    final selected = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => AppPlaceSheet.show(
                context,
                _hellsGate,
                onRoute: (_) async => fail('Directions bypassed the handoff'),
                onPlaceRoute: (context, place) async {
                  selected.add(place.id);
                },
              ),
              child: const Text('Open place'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open place'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Route'));
    await tester.pumpAndSettle();
    expect(selected, ['hg']);
    expect(find.text("Hell's Gate National Park"), findsNothing);
  });
}
