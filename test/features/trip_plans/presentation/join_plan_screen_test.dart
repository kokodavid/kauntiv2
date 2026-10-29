import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaunti47_v2/src/features/trip_plans/application/plan_collaboration_providers.dart';
import 'package:kaunti47_v2/src/features/trip_plans/application/planned_trips_list.dart';
import 'package:kaunti47_v2/src/features/trip_plans/application/trip_plans_providers.dart';
import 'package:kaunti47_v2/src/features/trip_plans/domain/plan_failure.dart';
import 'package:kaunti47_v2/src/features/trip_plans/domain/plan_invite.dart';
import 'package:kaunti47_v2/src/features/trip_plans/domain/plan_member.dart';
import 'package:kaunti47_v2/src/features/trip_plans/presentation/join_plan_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../fake_plan_collaboration_repository.dart';
import '../fake_trip_plans_repository.dart';

void main() {
  late FakePlanCollaborationRepository collaboration;
  String? opened;
  var signInTaps = 0;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    PlannedTripsList.resetSessionForTest();
    collaboration = FakePlanCollaborationRepository();
    opened = null;
    signInTaps = 0;
  });

  Future<void> pump(WidgetTester tester, {bool signedIn = true}) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          planCollaborationRepositoryProvider.overrideWithValue(collaboration),
          tripPlansRepositoryProvider.overrideWithValue(
            FakeTripPlansRepository(),
          ),
        ],
        child: MaterialApp(
          home: JoinPlanScreen(
            token: 'tok',
            signedIn: signedIn,
            onOpenPlan: (id) => opened = id,
            onClose: () {},
            onSignIn: () => signInTaps++,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('a good link names the plan and joins it', (tester) async {
    await pump(tester);
    expect(find.text('mwangi_j invited you to Naivasha weekend'), findsOneWidget);
    await tester.tap(find.text('Join plan'));
    await tester.pumpAndSettle();
    expect(collaboration.joined, ['tok']);
    expect(opened, 'plan-9');
  });

  testWidgets('a view-only link says so', (tester) async {
    collaboration.preview = const InvitePreview(
      state: InviteState.ok,
      planId: 'plan-9',
      title: 'Naivasha weekend',
      role: PlanRole.viewer,
    );
    await pump(tester);
    expect(
      find.text("You'll be able to see this plan, not change it."),
      findsOneWidget,
    );
  });

  testWidgets('already a member: opens the plan', (tester) async {
    collaboration.preview = const InvitePreview(
      state: InviteState.alreadyMember,
      planId: 'plan-9',
      title: 'Naivasha weekend',
    );
    await pump(tester);
    await tester.tap(find.text('Open plan'));
    expect(opened, 'plan-9');
  });

  for (final (state, text) in [
    (InviteState.expired, 'This link has expired'),
    (InviteState.revoked, 'This link was turned off'),
    (InviteState.full, 'This plan is full'),
    (InviteState.invalid, "We can't find this invite"),
  ]) {
    testWidgets('$state shows its message and no Join button', (tester) async {
      collaboration.preview = InvitePreview(state: state);
      await pump(tester);
      expect(find.text(text), findsOneWidget);
      expect(find.text('Join plan'), findsNothing);
    });
  }

  testWidgets('signed out: asks to sign in', (tester) async {
    await pump(tester, signedIn: false);
    expect(find.text('Sign in to join this plan'), findsOneWidget);
    await tester.tap(find.text('Sign in'));
    expect(signInTaps, 1);
  });

  testWidgets('a refused join stays on the page with the reason', (
    tester,
  ) async {
    collaboration.joinFails = PlanFailureKind.inviteFull;
    await pump(tester);
    await tester.tap(find.text('Join plan'));
    await tester.pumpAndSettle();
    expect(opened, isNull);
    expect(find.text("Couldn't join"), findsOneWidget);
  });
}
