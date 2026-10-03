import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../design/app_colors.dart';
import '../../../widgets/app_progress_indicator.dart';
import '../../auth/application/auth_providers.dart';
import '../../detection/application/detection_controller.dart';
import '../../onboarding/application/startup_flow.dart';
import '../application/account_deletion_providers.dart';
import 'confirm_dialog.dart';

/// Settings > Delete account. Irreversible (security plan: "Your badges,
/// Trips, handle and photo are removed for good"), so this asks for
/// confirmation first via the shared stacked-confirm dialog shape (also
/// used by Sign out), with the danger color as its primary button.
Future<void> showDeleteAccountDialog(
  BuildContext context,
  WidgetRef ref,
) async {
  final confirmed = await showStackedConfirmDialog(
    context,
    title: 'Delete your account?',
    body:
        'Your badges, Trips, handle and photo are removed for good. '
        "This can't be undone.",
    primaryLabel: 'Delete account',
    primaryColor: AppColors.danger,
  );
  if (!confirmed || !context.mounted) return;

  unawaited(
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: AppProgressIndicator(color: AppColors.accent, radius: 14),
      ),
    ),
  );

  final repository = ref.read(accountDeletionRepositoryProvider);
  final detection = ref.read(detectionControllerProvider.notifier);
  final auth = ref.read(authServiceProvider);
  final startup = ref.read(startupFlowProvider.notifier);
  try {
    if (repository == null) {
      throw StateError('Account deletion is unavailable for this build.');
    }
    await detection.suspendForSignOut();
    await repository.deleteAccount();
    // The row behind this session's refresh token is gone; sign out
    // locally so the router's redirect sends the app back to sign-in.
    await auth.signOut();
    startup.resetAfterSignOut();
    if (context.mounted) Navigator.of(context).pop();
  } on Object {
    detection.resumeAfterSignOutFailure();
    if (context.mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Couldn't delete your account. Try again."),
        ),
      );
    }
  }
}
