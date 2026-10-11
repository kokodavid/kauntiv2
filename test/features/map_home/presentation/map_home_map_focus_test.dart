import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaunti47_v2/src/features/map_home/presentation/map_home_map_focus.dart';

void main() {
  test('a tap does not hide anything', () {
    final focus = MapHomeMapFocus();
    focus.down(1, Offset.zero);
    focus.move(1, const Offset(4, 3));
    focus.end(1);
    expect(focus.isBusy, isFalse);
    focus.dispose();
  });

  test('a second finger counts as working the map straight away', () {
    final focus = MapHomeMapFocus();
    focus.down(1, Offset.zero);
    focus.down(2, const Offset(50, 50));
    expect(focus.isBusy, isTrue);
    focus.dispose();
  });

  testWidgets('a drag hides the chrome until 3 seconds after it ends', (
    tester,
  ) async {
    final focus = MapHomeMapFocus();
    addTearDown(focus.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Stack(
          children: [
            MapHomeMapTouchSensor(
              focus: focus,
              child: const SizedBox.expand(),
            ),
            Positioned(
              top: 0,
              left: 0,
              child: MapHomeFocusFade(
                focus: focus,
                child: const SizedBox(key: Key('chrome'), width: 50, height: 50),
              ),
            ),
          ],
        ),
      ),
    );
    double opacity() => tester
        .widget<AnimatedOpacity>(find.byType(AnimatedOpacity))
        .opacity;

    final gesture = await tester.startGesture(const Offset(300, 400));
    await gesture.moveBy(const Offset(60, 0));
    await tester.pump();
    expect(focus.isBusy, isTrue);
    expect(opacity(), 0);

    await gesture.up();
    await tester.pump(const Duration(seconds: 2));
    expect(opacity(), 0);

    // A new touch inside the wait keeps it hidden and restarts the wait.
    final again = await tester.startGesture(const Offset(300, 400));
    await tester.pump(const Duration(seconds: 2));
    await again.up();
    await tester.pump(const Duration(seconds: 2));
    expect(opacity(), 0);

    await tester.pump(const Duration(seconds: 2));
    expect(focus.isBusy, isFalse);
    expect(opacity(), 1);
  });
}
