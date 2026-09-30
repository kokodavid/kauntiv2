import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaunti47_v2/src/core/services/supabase_client_provider.dart';
import 'package:kaunti47_v2/src/design/app_colors.dart';
import 'package:kaunti47_v2/src/features/auth/application/auth_providers.dart';
import 'package:kaunti47_v2/src/features/profile/presentation/profile_header.dart';
import 'package:kaunti47_v2/src/features/profile/presentation/profile_screen.dart';
import 'package:kaunti47_v2/src/features/profile/presentation/profile_tiles.dart';

void main() {
  testWidgets('Profile header uses the v2 blue treatment', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ProfileHeader(name: 'David', email: 'david@example.com'),
        ),
      ),
    );

    final avatar = tester.widget<CircleAvatar>(find.byType(CircleAvatar));
    expect(avatar.backgroundColor, AppColors.accent);
    final headerDecorations = tester.widgetList<DecoratedBox>(
      find.descendant(
        of: find.byType(ProfileHeader),
        matching: find.byType(DecoratedBox),
      ),
    );
    expect(
      headerDecorations.any(
        (widget) =>
            widget.decoration is BoxDecoration &&
            (widget.decoration as BoxDecoration).color == ProfilePalette.surface,
      ),
      isTrue,
    );
  });

  testWidgets('Profile keeps account content hidden until auth resolves', (
    tester,
  ) async {
    final auth = StreamController<String?>();
    addTearDown(auth.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          supabaseClientProvider.overrideWithValue(null),
          authUserIdProvider.overrideWith((ref) => auth.stream),
        ],
        child: MaterialApp(
          home: ProfileScreen(
            onOpenBadges: () {},
            onOpenSettings: () async {},
          ),
        ),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Your progress'), findsNothing);
    expect(find.text('Sign out'), findsNothing);

    auth.add(null);
    await tester.pump();
    expect(find.text('Sign in to see your profile.'), findsOneWidget);
    expect(find.text('Your progress'), findsNothing);
  });
}
