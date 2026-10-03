import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaunti47_v2/src/core/services/supabase_client_provider.dart';
import 'package:kaunti47_v2/src/design/app_colors.dart';
import 'package:kaunti47_v2/src/features/auth/application/auth_providers.dart';
import 'package:kaunti47_v2/src/features/badges/domain/badge_collection.dart';
import 'package:kaunti47_v2/src/features/profile/domain/trip_stats.dart';
import 'package:kaunti47_v2/src/features/profile/presentation/profile_header.dart';
import 'package:kaunti47_v2/src/features/profile/presentation/profile_progress_card.dart';
import 'package:kaunti47_v2/src/features/profile/presentation/profile_screen.dart';
import 'package:kaunti47_v2/src/features/profile/presentation/profile_tiles.dart';

void main() {
  testWidgets('Profile header uses the v2 blue treatment', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ProfileHeader(
            name: 'David',
            handle: 'david',
            avatarUrl: null,
            homeCounty: 'Nairobi',
            isPro: false,
            onOpenSettings: () {},
            onEditProfile: () {},
          ),
        ),
      ),
    );

    final avatar = tester.widget<CircleAvatar>(find.byType(CircleAvatar));
    expect(avatar.backgroundColor, AppColors.accent);
    expect(find.text('Home · Nairobi'), findsOneWidget);
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
            (widget.decoration as BoxDecoration).color ==
                ProfilePalette.surface,
      ),
      isTrue,
    );
  });

  testWidgets('profile progress uses current county collection', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 240));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final collection = BadgeCollection.from(
      visitStates: const {47: 'explored'},
      ranks: const {},
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ProfileProgressCard(
            collection: AsyncData<BadgeCollection>(collection),
            onRetry: () {},
            tripStats: const AsyncData(TripStats.zero),
          ),
        ),
      ),
    );

    expect(find.text('KENYA CLAIMED'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
    expect(find.text('/ 47 counties'), findsOneWidget);
    expect(find.textContaining('more count'), findsOneWidget);
    expect(tester.takeException(), isNull);
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
          home: ProfileScreen(onOpenBadges: () {}, onOpenSettings: () async {}),
        ),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('KENYA CLAIMED'), findsNothing);
    expect(find.text('Sign out'), findsNothing);

    auth.add(null);
    await tester.pump();
    expect(find.text('Sign in to see your profile.'), findsOneWidget);
    expect(find.text('KENYA CLAIMED'), findsNothing);
  });
}
