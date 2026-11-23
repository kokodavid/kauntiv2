import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaunti47_v2/src/features/auth/application/auth_providers.dart';
import 'package:kaunti47_v2/src/features/trip_plans/application/plan_collaboration_providers.dart';
import 'package:kaunti47_v2/src/features/trip_plans/application/planned_trips_list.dart';
import 'package:kaunti47_v2/src/features/trip_plans/application/trip_plans_providers.dart';
import 'package:kaunti47_v2/src/features/trip_plans/domain/plan_invite.dart';
import 'package:kaunti47_v2/src/features/trip_plans/domain/plan_limits.dart';
import 'package:kaunti47_v2/src/features/trip_plans/domain/plan_member.dart';
import 'package:kaunti47_v2/src/features/trip_plans/domain/trip_plan_summary.dart';
import 'package:kaunti47_v2/src/features/trip_plans/presentation/planned_view.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../fake_plan_collaboration_repository.dart';
import '../fake_trip_plans_repository.dart';

TripPlanSummary _plan(
  String title, {
  DateTime? start,
  PlanRole role = PlanRole.owner,
  bool past = false,
  List<int> counties = const [],
}) => TripPlanSummary(
  id: title,
  title: title,
  ownerId: role == PlanRole.owner ? 'me' : 'them',
  role: role,
  startDate: start,
  isPast: past,
  members: [
    const PlanMember(userId: 'me', role: PlanRole.owner, handle: 'amina7'),
    if (role != PlanRole.owner)
      const PlanMember(
        userId: 'them',
        role: PlanRole.owner,
        handle: 'mwangi_j',
      ),
  ],
  days: [
    PlanDaySummary(
      number: 1,
      countyCodes: counties,
      routeFresh: true,
      points: const [(-1.26, 36.8), (-0.72, 36.43)],
    ),
  ],
);

void main() {
  late FakeTripPlansRepository repository;
  late FakePlanCollaborationRepository collaboration;
  var planTripTaps = 0;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    PlannedTripsList.resetSessionForTest();
    repository = FakeTripPlansRepository();
    collaboration = FakePlanCollaborationRepository();
    planTripTaps = 0;
  });

  Future<void> pump(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tripPlansRepositoryProvider.overrideWithValue(repository),
          planCollaborationRepositoryProvider.overrideWithValue(collaboration),
          currentUserIdProvider.overrideWithValue(() => 'me'),
          planClaimedCountyCodesProvider.overrideWith((ref) async => {22}),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: PlannedView(
              header: const Text('switch'),
              homeCountyCode: 47,
              onPlanTrip: () => planTripTaps++,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'no plans: the example, the first-trip button and the allowance',
    (tester) async {
      await pump(tester);
      expect(find.text('Plan the trip. Claim new counties.'), findsOneWidget);
      expect(find.text('EXAMPLE PLAN'), findsOneWidget);
      expect(find.text('Mombasa day'), findsOneWidget);
      expect(
        find.text(
          'Free includes 3 upcoming plans of up to 3 days. Pro adds more.',
        ),
        findsOneWidget,
      );
      await tester.tap(find.text('Plan your first trip'));
      expect(planTripTaps, 1);
    },
  );

  testWidgets('plans: Upcoming soonest first, Shared with you, Past folded', (
    tester,
  ) async {
    repository.plans = [
      _plan('Coast long weekend', start: DateTime(2026, 12, 11)),
      _plan(
        'Naivasha weekend',
        start: DateTime(2026, 11, 14),
        counties: [47, 22, 32],
      ),
      _plan('Western circuit', role: PlanRole.editor),
      _plan('Amboseli day trip', start: DateTime(2026, 10, 3), past: true),
    ];
    await pump(tester);

    expect(find.text('Upcoming'), findsOneWidget);
    expect(find.text('2 of 3 upcoming plans'), findsOneWidget);
    final naivasha = tester.getTopLeft(find.text('Naivasha weekend')).dy;
    final coast = tester.getTopLeft(find.text('Coast long weekend')).dy;
    expect(naivasha, lessThan(coast));

    // Nairobi is home and Kiambu claimed, so only Nakuru is new.
    expect(
      find.textContaining('Passes through 3 counties', findRichText: true),
      findsOneWidget,
    );
    expect(find.text('1 new', findRichText: true), findsNothing);

    expect(find.text('Shared with you'), findsOneWidget);
    expect(find.text('From mwangi_j'), findsOneWidget);

    expect(find.text('Amboseli day trip'), findsNothing);
    await tester.tap(find.text('Show 1 ›'));
    await tester.pumpAndSettle();
    expect(find.text('Amboseli day trip'), findsOneWidget);
  });

  testWidgets('no plans but an invitation: it shows above the example', (
    tester,
  ) async {
    collaboration.invitations = const [
      PlanInvitation(
        planId: 'plan-7',
        title: 'Coast trip',
        role: PlanRole.editor,
        inviterHandle: 'mwangi_j',
      ),
    ];
    await pump(tester);
    expect(find.text('Invitations'), findsOneWidget);
    expect(find.text('Coast trip'), findsOneWidget);
    expect(find.text('Plan the trip. Claim new counties.'), findsOneWidget);
  });

  testWidgets('Pro users see no allowance line', (tester) async {
    repository.limits = PlanLimits.proTier;
    await pump(tester);
    expect(find.textContaining('Free:'), findsNothing);
  });
}
