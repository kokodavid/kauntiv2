import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaunti47_v2/src/features/onboarding/presentation/onboarding_privacy_note.dart';

void main() {
  testWidgets('tapping Privacy Policy opens the policy', (tester) async {
    var opened = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: OnboardingPrivacyNote(onOpen: () async => opened++),
        ),
      ),
    );

    final rich = tester.widget<RichText>(
      find.byWidgetPredicate(
        (w) => w is RichText && w.text.toPlainText().contains('Privacy Policy'),
      ),
    );
    expect(rich.text.toPlainText(), 'By continuing you accept our Privacy Policy.');

    late final TapGestureRecognizer tap;
    rich.text.visitChildren((span) {
      if (span is TextSpan && span.text == 'Privacy Policy') {
        tap = span.recognizer! as TapGestureRecognizer;
        return false;
      }
      return true;
    });
    tap.onTap!();
    expect(opened, 1);
  });
}
