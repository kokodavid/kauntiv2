import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/services/supabase_client_provider.dart';
import '../data/plan_collaboration_repository.dart';
import '../data/supabase_plan_collaboration_repository.dart';
import '../domain/plan_failure.dart';
import '../domain/plan_invite.dart';
import 'planned_trips_list.dart';

part 'plan_collaboration_providers.g.dart';

/// The sharing calls. Null when the build has no Supabase.
@riverpod
PlanCollaborationRepository? planCollaborationRepository(Ref ref) {
  final client = ref.watch(supabaseClientProvider);
  return client == null ? null : SupabasePlanCollaborationRepository(client);
}

/// What an invite link says before the person joins.
@riverpod
Future<InvitePreview> invitePreview(Ref ref, String token) async {
  final repository = ref.watch(planCollaborationRepositoryProvider);
  if (repository == null) throw const PlanFailure(PlanFailureKind.unavailable);
  return repository.previewInvite(token);
}

/// Joins a plan through a link, then refreshes the Planned list so the new
/// plan shows under Shared with you.
class PlanJoiner {
  PlanJoiner(this._ref);

  final Ref _ref;

  /// The plan's id, or why joining failed.
  Future<(PlanFailure?, String?)> join(String token) async {
    final repository = _ref.read(planCollaborationRepositoryProvider);
    if (repository == null) {
      return (const PlanFailure(PlanFailureKind.unavailable), null);
    }
    final String planId;
    try {
      planId = await repository.join(token);
    } on PlanFailure catch (failure) {
      return (failure, null);
    } on Object {
      return (const PlanFailure(PlanFailureKind.offline), null);
    }
    if (_ref.mounted) {
      await _ref.read(plannedTripsListProvider.notifier).refresh();
    }
    return (null, planId);
  }
}

@riverpod
PlanJoiner planJoiner(Ref ref) => PlanJoiner(ref);
