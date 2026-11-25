import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaunti47_v2/src/features/onboarding/presentation/onboarding_interests_page.dart';
import 'package:kaunti47_v2/src/features/profile/domain/place_interest.dart';

Widget _page({
  List<PlaceInterest> selected = const [],
  bool isSaving = false,
  ValueChanged<PlaceInterest>? onToggle,
  VoidCallback? onContinue,
  VoidCallback? onSkip,
}) => MaterialApp(
  home: OnboardingInterestsPage(
    options: PlaceInterest.values,
    selected: selected,
    isSaving: isSaving,
    onToggle: onToggle ?? (_) {},
    onContinue: onContinue ?? () {},
    onSkip: onSkip ?? () {},
    onBack: () {},
  ),
);

void main() {
  testWidgets('shows step 2 of 4 and every interest chip', (tester) async {
    await tester.pumpWidget(_page());
    expect(find.text('2 of 4'), findsOneWidget);
    expect(find.text('What do you like to see?'), findsOneWidget);
    for (final interest in PlaceInterest.values) {
      expect(find.text(interest.label), findsOneWidget);
    }
  });

  testWidgets('Continue is off until something is picked; skip is always on', (
    tester,
  ) async {
    var continued = 0;
    var skipped = 0;
    await tester.pumpWidget(
      _page(onContinue: () => continued++, onSkip: () => skipped++),
    );
    await tester.tap(find.text('Continue'));
    expect(continued, 0);
    await tester.tap(find.text('Skip for now'));
    expect(skipped, 1);

    await tester.pumpWidget(
      _page(
        selected: [PlaceInterest.coast],
        onContinue: () => continued++,
        onSkip: () => skipped++,
      ),
    );
    await tester.tap(find.text('Continue'));
    expect(continued, 1);
  });

  testWidgets('tapping a chip reports it', (tester) async {
    PlaceInterest? toggled;
    await tester.pumpWidget(_page(onToggle: (i) => toggled = i));
    await tester.tap(find.text('Lakes, rivers and waterfalls'));
    expect(toggled, PlaceInterest.water);
  });

  test('the hint says picks lean the suggestions, never an error', () {
    expect(
      OnboardingInterestsPage.hint(0),
      'Pick any number, or skip for now.',
    );
    expect(
      OnboardingInterestsPage.hint(2),
      '2 picked. For you leans toward these and still shows the rest.',
    );
  });

  test('known keys only, in canonical order', () {
    expect(PlaceInterest.fromKeys(['coast', 'bogus', 'nature', 'coast']), [
      PlaceInterest.nature,
      PlaceInterest.coast,
    ]);
    expect(PlaceInterest.fromKey('bogus'), isNull);
  });
}
