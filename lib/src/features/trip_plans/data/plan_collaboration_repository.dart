import '../domain/plan_invite.dart';
import '../domain/plan_member.dart';

/// Sharing a plan: invite links, invitations by username, and the people on
/// a plan. Every call is a database function that checks role and limits;
/// refusals arrive as `PlanFailure`.
abstract interface class PlanCollaborationRepository {
  /// Makes a link. The token is shown once; only its hash is stored.
  Future<PlanInviteLink> createInvite(String planId, {PlanRole? role});
  Future<void> revokeInvite(String inviteId);
  Future<List<PlanInviteInfo>> listInvites(String planId);

  /// What a link says before joining; never fails for a bad link.
  Future<InvitePreview> previewInvite(String token);

  /// Joins through a link; returns the plan's id.
  Future<String> join(String token);

  /// People by username, from 3 letters. Username and avatar only.
  Future<List<UsernameHit>> searchUsernames(String prefix);
  Future<void> inviteUser(String planId, String handle, {PlanRole? role});
  Future<List<PlanInvitation>> myInvitations();
  Future<void> respondInvitation(String planId, {required bool accept});

  Future<void> setMemberRole(String planId, String userId, PlanRole role);
  Future<void> removeMember(String planId, String userId);
  Future<void> leave(String planId);
  Future<void> handOver(String planId, String userId);
  Future<void> setMuted(String planId, {required bool muted});
}
