import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:kaunti47_v2/src/config/app_config.dart';
import 'package:kaunti47_v2/src/core/services/app_config_provider.dart';
import 'package:kaunti47_v2/src/features/auth/application/auth_providers.dart';
import 'package:kaunti47_v2/src/features/trip_plans/application/plan_collaboration_providers.dart';
import 'package:kaunti47_v2/src/features/trip_plans/presentation/plan_header_people.dart';
import 'package:kaunti47_v2/src/features/trip_plans/application/plan_live.dart';
import 'package:kaunti47_v2/src/features/trip_plans/application/plan_routing_providers.dart';
import 'package:kaunti47_v2/src/features/trip_plans/application/planned_trips_list.dart';
import 'package:kaunti47_v2/src/features/trip_plans/application/trip_plans_providers.dart';
import 'package:kaunti47_v2/src/features/trip_plans/domain/plan_invite.dart';
import 'package:kaunti47_v2/src/features/trip_plans/domain/plan_day.dart';
import 'package:kaunti47_v2/src/features/trip_plans/domain/plan_limits.dart';
import 'package:kaunti47_v2/src/features/trip_plans/domain/plan_member.dart';
import 'package:kaunti47_v2/src/features/trip_plans/domain/plan_place.dart';
import 'package:kaunti47_v2/src/features/trip_plans/domain/trip_plan.dart';
import 'package:kaunti47_v2/src/features/trip_plans/presentation/plan_screen.dart';
import 'package:kaunti47_v2/src/features/trip_plans/presentation/planned_invitations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../fake_plan_collaboration_repository.dart';
import '../fake_plan_live_source.dart';
import '../fake_plan_routing_client.dart';
import '../fake_trip_plans_repository.dart';

TripPlan _plan({
  PlanRole role = PlanRole.owner,
  PlanLimits limits = PlanLimits.free,
  bool buddy = true,
}) => TripPlan(
  id: 'plan-1',
  title: 'Naivasha weekend',
  ownerId: role == PlanRole.owner ? 'me' : 'owner-1',
  role: role,
  start: const PlanStart(kind: PlanStartKind.currentLocation),
  limits: limits,
  members: [
    PlanMember(
      userId: role == PlanRole.owner ? 'me' : 'owner-1',
      role: PlanRole.owner,
      handle: role == PlanRole.owner ? 'amina7' : 'mwangi_j',
    ),
    if (buddy)
      PlanMember(
        userId: role == PlanRole.owner ? 'buddy-1' : 'me',
        role: role == PlanRole.owner ? PlanRole.editor : role,
        handle: role == PlanRole.owner ? 'nyati7' : 'amina7',
      ),
  ],
);

void main() {
  late FakeTripPlansRepository repository;
  late FakePlanCollaborationRepository collaboration;
  late FakePlanLiveSource live;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    PlannedTripsList.resetSessionForTest();
    repository = FakeTripPlansRepository();
    collaboration = FakePlanCollaborationRepository();
    live = FakePlanLiveSource();
  });

  List<Override> overrides() => [
    appConfigProvider.overrideWithValue(const AppConfig.dev()),
    tripPlansRepositoryProvider.overrideWithValue(repository),
    planCollaborationRepositoryProvider.overrideWithValue(collaboration),
    planLiveSourceProvider.overrideWithValue(live),
    planLivePollIntervalProvider.overrideWithValue(null),
    currentUserIdProvider.overrideWithValue(() => 'me'),
    planRoutingClientProvider.overrideWithValue(FakePlanRoutingClient()),
    planClaimedCountyCodesProvider.overrideWith((ref) async => {}),
  ];

  Future<void> open(WidgetTester tester, TripPlan plan) async {
    repository.detail['plan-1'] = plan;
    await tester.pumpWidget(
      ProviderScope(
        overrides: overrides(),
        child: MaterialApp(
          home: PlanScreen(planId: 'plan-1', onBack: () {}),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
  }

  Future<void> openMenu(WidgetTester tester) async {
    await tester.tap(find.byTooltip('Plan options'));
    await tester.pumpAndSettle();
  }

  testWidgets('a view-only member sees the note and only People and Leave', (
    tester,
  ) async {
    await open(tester, _plan(role: PlanRole.viewer));
    expect(
      find.text('You can see this plan but not change it.'),
      findsOneWidget,
    );
    await openMenu(tester);
    expect(find.text('Members'), findsOneWidget);
    expect(find.text('Leave plan'), findsOneWidget);
    expect(find.text('Rename'), findsNothing);
    expect(find.byTooltip('Invite people'), findsNothing);
    expect(find.text('Delete plan'), findsNothing);
  });

  testWidgets('a Free editor can edit but not invite', (tester) async {
    await open(tester, _plan(role: PlanRole.editor));
    await openMenu(tester);
    expect(find.text('Rename'), findsOneWidget);
    await tester.tapAt(Offset.zero);
    await tester.pumpAndSettle();
    expect(find.text('Invite'), findsNothing);
  });

  testWidgets('the owner makes a link and it can be copied', (tester) async {
    await open(tester, _plan(buddy: false));
    await tester.tap(find.byType(PlanInvitePill));
    await tester.pumpAndSettle();
    expect(find.text('They can add and move places. Only usernames are shown.'), findsOneWidget);
    await tester.tap(find.text('Create invite link'));
    await tester.pumpAndSettle();
    expect(collaboration.calls, ['create|plan-1|editor']);
    expect(find.text('kaunti47.com/p/tok'), findsOneWidget);
    expect(find.text('Copy'), findsOneWidget);
  });

  testWidgets('Pro offers View only for the link', (tester) async {
    await open(tester, _plan(limits: PlanLimits.proTier));
    await tester.tap(find.byType(PlanInvitePill));
    await tester.pumpAndSettle();
    await tester.tap(find.text('View only'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Create invite link'));
    await tester.pumpAndSettle();
    expect(collaboration.calls, ['create|plan-1|viewer']);
  });

  testWidgets('searching by username and inviting', (tester) async {
    collaboration.hits = const [UsernameHit(handle: 'nyati7')];
    await open(tester, _plan(buddy: false));
    await tester.tap(find.byType(PlanInvitePill));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'nya');
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Invite'));
    await tester.pumpAndSettle();
    expect(collaboration.calls, ['invite|plan-1|nyati7']);
  });

  testWidgets('the owner removes a person from People', (tester) async {
    await open(tester, _plan());
    await openMenu(tester);
    await tester.tap(find.text('Members'));
    await tester.pumpAndSettle();
    expect(find.text('amina7 (you)'), findsOneWidget);
    expect(find.text('nyati7'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.more_vert).last);
    await tester.pumpAndSettle();
    expect(find.text('Make owner'), findsOneWidget);
    await tester.tap(find.text('Remove'));
    await tester.pumpAndSettle();
    expect(collaboration.calls, ['remove|plan-1|buddy-1']);
  });

  testWidgets('a change someone else makes reads the plan again', (
    tester,
  ) async {
    await open(tester, _plan());
    final before = repository.getCalls;
    live.emit();
    live.emit();
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(repository.getCalls, before + 1);
  });

  testWidgets('invitations on Planned: Accept joins and opens the plan', (
    tester,
  ) async {
    String? opened;
    collaboration.invitations = const [
      PlanInvitation(
        planId: 'plan-7',
        title: 'Coast trip',
        role: PlanRole.editor,
        inviterHandle: 'mwangi_j',
      ),
    ];
    repository.plans = [];
    await tester.pumpWidget(
      ProviderScope(
        overrides: overrides(),
        child: MaterialApp(
          home: Scaffold(
            body: Consumer(
              builder: (context, ref, _) =>
                  PlannedInvitations(onOpenPlan: (_, id) => opened = id),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Coast trip'), findsOneWidget);
    expect(find.textContaining('mwangi_j invited you'), findsOneWidget);
    await tester.tap(find.text('Accept'));
    await tester.pumpAndSettle();
    expect(collaboration.calls, ['respond|plan-7|true']);
    expect(opened, 'plan-7');
  });

  testWidgets('a shared plan shows who changed it and what is new', (
    tester,
  ) async {
    final now = DateTime.now();
    final base = _plan();
    await open(
      tester,
      TripPlan(
        id: base.id,
        title: base.title,
        ownerId: base.ownerId,
        role: base.role,
        start: base.start,
        limits: base.limits,
        members: base.members,
        updatedAt: now.subtract(const Duration(seconds: 20)),
        updatedByHandle: 'nyati7',
        days: [
          PlanDay(
            id: 'd1',
            number: 1,
            stops: [
              PlanStop(
                id: 's1',
                addedBy: 'buddy-1',
                addedByHandle: 'nyati7',
                updatedAt: now.subtract(const Duration(seconds: 20)),
                place: const PlanPlace(
                  id: 'p1',
                  name: 'Hell\'s Gate',
                  type: 'waterfall',
                  countyCode: 32,
                  lat: -0.9,
                  lng: 36.3,
                ),
              ),
            ],
          ),
        ],
      ),
    );
    expect(find.text('Updated by nyati7 just now'), findsOneWidget);
    expect(find.text('Added by nyati7 · just now'), findsOneWidget);
  });

  testWidgets('Mute updates on a shared plan, and Unmute afterwards', (
    tester,
  ) async {
    await open(tester, _plan());
    await openMenu(tester);
    await tester.tap(find.text('Mute updates'));
    await tester.pumpAndSettle();
    expect(collaboration.calls, ['mute|plan-1|true']);
    expect(find.text('Updates muted'), findsOneWidget);
    await openMenu(tester);
    expect(find.text('Unmute updates'), findsOneWidget);
  });

  testWidgets('a solo plan has no Mute item', (tester) async {
    await open(tester, _plan(buddy: false));
    await openMenu(tester);
    expect(find.text('Mute updates'), findsNothing);
  });
}
