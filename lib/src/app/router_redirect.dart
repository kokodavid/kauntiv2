import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/domain/app_feature_flags.dart';
import '../core/services/pending_invite.dart';
import '../features/app_version/application/app_update_providers.dart';
import '../features/journeys/application/journey_recorder.dart';
import '../features/onboarding/application/startup_flow.dart';
import '../features/onboarding/domain/startup_state.dart';
import 'app_routes.dart';

/// The router's one redirect: start-up and release gates, plus remembering a
/// plan invite link that arrives before onboarding is done.
String? routerRedirect(Ref ref, String location) {
  final journeyActive =
      AppFeatureFlags.journeys && ref.read(journeyRecorderProvider) != null;
  final update = ref.read(appUpdateControllerProvider);
  final step = ref.read(startupFlowProvider).step;
  final invites = ref.read(pendingInviteProvider.notifier);
  final code = AppRoutes.inviteCode(location);
  // Onboarding comes first; the link waits for it.
  if (code != null && step != StartupStep.ready) invites.remember(code);
  final pending = ref.read(pendingInviteProvider);
  final target = AppRoutes.redirect(
    step,
    location,
    updateRequired: update?.required == true && !journeyActive,
    pendingInvite: pending,
  );
  if (pending != null && target == AppRoutes.join(pending)) invites.clear();
  return target;
}
