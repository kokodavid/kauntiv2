import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/plan_collaboration_repository.dart';
import '../domain/plan_failure.dart';
import '../domain/plan_invite.dart';
import '../domain/plan_member.dart';
import 'plan_collaboration_providers.dart';
import 'plan_detail.dart';
import 'planned_trips_list.dart';

part 'plan_sharing.g.dart';

/// The live invite links of a plan, for the invite sheet.
@riverpod
Future<List<PlanInviteInfo>> planInvites(Ref ref, String planId) async {
  final repository = ref.watch(planCollaborationRepositoryProvider);
  if (repository == null) return const [];
  return repository.listInvites(planId);
}

/// People matching what was typed (3 letters or more).
@riverpod
Future<List<UsernameHit>> usernameSearch(Ref ref, String prefix) async {
  final repository = ref.watch(planCollaborationRepositoryProvider);
  if (repository == null || prefix.trim().length < 3) return const [];
  return repository.searchUsernames(prefix.trim());
}

/// Whether I muted this plan: no pushes about changes or joins.
@riverpod
Future<bool> planMuted(Ref ref, String planId) async {
  try {
    final repository = ref.watch(planCollaborationRepositoryProvider);
    return await repository?.isMuted(planId) ?? false;
  } on Object {
    return false;
  }
}

/// Plans people invited me to by username, waiting for my answer.
@riverpod
Future<List<PlanInvitation>> myPlanInvitations(Ref ref) async {
  try {
    final repository = ref.watch(planCollaborationRepositoryProvider);
    if (repository == null) return const [];
    return await repository.myInvitations();
  } on Object {
    return const [];
  }
}

/// Every sharing change. Each goes to the server (which checks role and
/// limits), then the plan and the Planned list are read again. Returns
/// null when it worked, or why it didn't.
class PlanSharing {
  PlanSharing(this._ref);

  final Ref _ref;

  Future<PlanFailure?> _run(
    String planId,
    Future<void> Function(PlanCollaborationRepository repository) change, {
    bool leaving = false,
  }) async {
    final repository = _ref.read(planCollaborationRepositoryProvider);
    if (repository == null) return const PlanFailure(PlanFailureKind.unavailable);
    try {
      await change(repository);
    } on PlanFailure catch (failure) {
      return failure;
    } on Object {
      return const PlanFailure(PlanFailureKind.offline);
    }
    if (_ref.mounted) {
      if (!leaving) {
        await _ref.read(planDetailProvider(planId).notifier).refresh();
      }
      await _ref.read(plannedTripsListProvider.notifier).refresh();
    }
    return null;
  }

  /// A new link and nothing else; the link needs no plan refresh.
  Future<(PlanFailure?, PlanInviteLink?)> createLink(
    String planId,
    PlanRole role,
  ) async {
    final repository = _ref.read(planCollaborationRepositoryProvider);
    if (repository == null) {
      return (const PlanFailure(PlanFailureKind.unavailable), null);
    }
    try {
      final link = await repository.createInvite(planId, role: role);
      if (_ref.mounted) _ref.invalidate(planInvitesProvider(planId));
      return (null, link);
    } on PlanFailure catch (failure) {
      return (failure, null);
    } on Object {
      return (const PlanFailure(PlanFailureKind.offline), null);
    }
  }

  Future<PlanFailure?> revokeLink(String planId, String inviteId) async {
    final failure = await _run(
      planId,
      (r) => r.revokeInvite(inviteId),
    );
    if (failure == null && _ref.mounted) {
      _ref.invalidate(planInvitesProvider(planId));
    }
    return failure;
  }

  Future<PlanFailure?> inviteUser(
    String planId,
    String handle,
    PlanRole role,
  ) => _run(planId, (r) => r.inviteUser(planId, handle, role: role));

  Future<PlanFailure?> setRole(String planId, String userId, PlanRole role) =>
      _run(planId, (r) => r.setMemberRole(planId, userId, role));

  Future<PlanFailure?> remove(String planId, String userId) =>
      _run(planId, (r) => r.removeMember(planId, userId));

  Future<PlanFailure?> handOver(String planId, String userId) =>
      _run(planId, (r) => r.handOver(planId, userId));

  Future<PlanFailure?> leave(String planId) => _run(
    planId,
    (r) => r.leave(planId),
    leaving: true,
  );

  Future<PlanFailure?> setMuted(String planId, {required bool muted}) async {
    final repository = _ref.read(planCollaborationRepositoryProvider);
    if (repository == null) return const PlanFailure(PlanFailureKind.unavailable);
    try {
      await repository.setMuted(planId, muted: muted);
    } on PlanFailure catch (failure) {
      return failure;
    } on Object {
      return const PlanFailure(PlanFailureKind.offline);
    }
    if (_ref.mounted) _ref.invalidate(planMutedProvider(planId));
    return null;
  }

  /// Accept or decline an invitation by username.
  Future<PlanFailure?> respond(String planId, {required bool accept}) async {
    final failure = await _run(
      planId,
      (r) => r.respondInvitation(planId, accept: accept),
      leaving: true,
    );
    if (failure == null && _ref.mounted) _ref.invalidate(myPlanInvitationsProvider);
    return failure;
  }
}

@riverpod
PlanSharing planSharing(Ref ref) => PlanSharing(ref);
