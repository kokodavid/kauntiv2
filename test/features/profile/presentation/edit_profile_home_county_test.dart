import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaunti47_v2/src/counties/county_paths.dart';
import 'package:kaunti47_v2/src/features/profile/presentation/edit_profile_home_county.dart';

void main() {
  testWidgets('shows the current home county and Change', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: EditProfileHomeCounty(
            county: CountyPaths.bySlug['marsabit'],
            onChanged: (_) {},
          ),
        ),
      ),
    );
    expect(find.text('Home county'), findsOneWidget);
    expect(find.text('Marsabit'), findsOneWidget);
    expect(find.text('Change'), findsOneWidget);
  });

  testWidgets('says Not set when there is no home county yet', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: EditProfileHomeCounty(county: null, onChanged: (_) {}),
        ),
      ),
    );
    expect(find.text('Not set'), findsOneWidget);
  });
}
