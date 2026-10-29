import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/plan_failure.dart';
import '../domain/plan_invite.dart';
import '../domain/plan_member.dart';
import 'plan_collaboration_repository.dart';
import 'plan_rpc.dart';

/// [PlanCollaborationRepository] over
/// `supabase/migrations/20261101105000_trip_plan_collaboration.sql`.
class SupabasePlanCollaborationRepository
    implements PlanCollaborationRepository {
  const SupabasePlanCollaborationRepository(this.client);

  final SupabaseClient client;

  Future<Object?> _call(String fn, [Map<String, Object?>? params]) =>
      callPlanRpc(client, fn, params);

  static String _role(PlanRole? role) => (role ?? PlanRole.editor).name;

  @override
  Future<PlanInviteLink> createInvite(String planId, {PlanRole? role}) async {
    final result = await _call('create_trip_plan_invite', {
      'p_plan': planId,
      'p_role': _role(role),
    });
    final link = PlanInviteLink.fromJson(result);
    if (link == null) throw const PlanFailure(PlanFailureKind.unknown);
    return link;
  }

  @override
  Future<void> revokeInvite(String inviteId) =>
      _call('revoke_trip_plan_invite', {'p_invite': inviteId});

  @override
  Future<List<PlanInviteInfo>> listInvites(String planId) async {
    final result = await _call('list_trip_plan_invites', {'p_plan': planId});
    return [
      if (result is List)
        for (final raw in result) ?PlanInviteInfo.fromJson(raw),
    ];
  }

  @override
  Future<InvitePreview> previewInvite(String token) async =>
      InvitePreview.fromJson(
        await _call('preview_trip_plan_invite', {'p_token': token}),
      );

  @override
  Future<String> join(String token) async {
    final result = await _call('join_trip_plan', {'p_token': token});
    if (result is! String) throw const PlanFailure(PlanFailureKind.unknown);
    return result;
  }

  @override
  Future<List<UsernameHit>> searchUsernames(String prefix) async {
    final result = await _call('search_usernames', {'p_prefix': prefix});
    return [
      if (result is List)
        for (final raw in result) ?UsernameHit.fromJson(raw),
    ];
  }

  @override
  Future<void> inviteUser(String planId, String handle, {PlanRole? role}) =>
      _call('invite_trip_plan_user', {
        'p_plan': planId,
        'p_handle': handle,
        'p_role': _role(role),
      });

  @override
  Future<List<PlanInvitation>> myInvitations() async {
    final result = await _call('my_trip_plan_invitations');
    return [
      if (result is List)
        for (final raw in result) ?PlanInvitation.fromJson(raw),
    ];
  }

  @override
  Future<void> respondInvitation(String planId, {required bool accept}) =>
      _call('respond_trip_plan_invitation', {
        'p_plan': planId,
        'p_accept': accept,
      });

  @override
  Future<void> setMemberRole(String planId, String userId, PlanRole role) =>
      _call('set_trip_plan_member_role', {
        'p_plan': planId,
        'p_user': userId,
        'p_role': role.name,
      });

  @override
  Future<void> removeMember(String planId, String userId) =>
      _call('remove_trip_plan_member', {'p_plan': planId, 'p_user': userId});

  @override
  Future<void> leave(String planId) =>
      _call('leave_trip_plan', {'p_plan': planId});

  @override
  Future<void> handOver(String planId, String userId) =>
      _call('hand_over_trip_plan', {'p_plan': planId, 'p_user': userId});

  @override
  Future<void> setMuted(String planId, {required bool muted}) =>
      _call('set_trip_plan_muted', {'p_plan': planId, 'p_muted': muted});
}
