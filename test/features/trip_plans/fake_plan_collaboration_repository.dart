import 'package:kaunti47_v2/src/features/trip_plans/data/plan_collaboration_repository.dart';
import 'package:kaunti47_v2/src/features/trip_plans/domain/plan_failure.dart';
import 'package:kaunti47_v2/src/features/trip_plans/domain/plan_invite.dart';
import 'package:kaunti47_v2/src/features/trip_plans/domain/plan_member.dart';

/// An in-memory [PlanCollaborationRepository] for tests.
class FakePlanCollaborationRepository implements PlanCollaborationRepository {
  InvitePreview preview = const InvitePreview(
    state: InviteState.ok,
    planId: 'plan-9',
    title: 'Naivasha weekend',
    inviterHandle: 'mwangi_j',
  );
  PlanFailureKind? joinFails;
  final joined = <String>[];
  final calls = <String>[];
  List<UsernameHit> hits = const [];
  List<PlanInvitation> invitations = const [];

  @override
  Future<InvitePreview> previewInvite(String token) async => preview;

  @override
  Future<String> join(String token) async {
    final kind = joinFails;
    if (kind != null) throw PlanFailure(kind);
    joined.add(token);
    return preview.planId ?? 'plan-9';
  }

  @override
  Future<List<UsernameHit>> searchUsernames(String prefix) async => hits;

  @override
  Future<PlanInviteLink> createInvite(String planId, {PlanRole? role}) async {
    calls.add('create|$planId|${role?.name}');
    return PlanInviteLink(
      id: 'invite-1',
      token: 'tok',
      role: role ?? PlanRole.editor,
      expiresAt: DateTime(2026, 12, 1),
    );
  }

  @override
  Future<void> revokeInvite(String inviteId) async =>
      calls.add('revoke|$inviteId');

  @override
  Future<List<PlanInviteInfo>> listInvites(String planId) async => const [];

  @override
  Future<void> inviteUser(String planId, String handle, {PlanRole? role}) async =>
      calls.add('invite|$planId|$handle');

  @override
  Future<List<PlanInvitation>> myInvitations() async => invitations;

  @override
  Future<void> respondInvitation(String planId, {required bool accept}) async =>
      calls.add('respond|$planId|$accept');

  @override
  Future<void> setMemberRole(String planId, String userId, PlanRole role) async =>
      calls.add('role|$planId|$userId|${role.name}');

  @override
  Future<void> removeMember(String planId, String userId) async =>
      calls.add('remove|$planId|$userId');

  @override
  Future<void> leave(String planId) async => calls.add('leave|$planId');

  @override
  Future<void> handOver(String planId, String userId) async =>
      calls.add('handover|$planId|$userId');

  @override
  Future<void> setMuted(String planId, {required bool muted}) async =>
      calls.add('mute|$planId|$muted');
}
