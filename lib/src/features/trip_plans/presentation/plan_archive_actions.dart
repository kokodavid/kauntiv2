import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/app_floating_toast.dart';
import '../application/plan_editor.dart';
import 'plan_edit_sheets.dart';

/// Archiving a plan and bringing it back. Archiving keeps everything: the
/// plan just moves to Archived at the bottom of Planned.
class PlanArchiveActions {
  const PlanArchiveActions(this.context, this.ref);

  final BuildContext context;
  final WidgetRef ref;

  PlanEditor get _editor => ref.read(planEditorProvider);

  /// Asks first, then archives. True when it was archived.
  Future<bool> archive(String planId) async {
    final ok = await showPlanConfirm(
      context,
      title: 'Archive this plan?',
      message:
          'It moves to Archived on the Planned tab and stops counting toward '
          'your upcoming plans. You can bring it back any time.',
      action: 'Archive',
      icon: Icons.archive_outlined,
      destructive: false,
    );
    if (!ok) return false;
    final failure = await _editor.archive(planId);
    if (failure != null && context.mounted) {
      reportPlanFailure(context, failure);
    }
    return failure == null;
  }

  /// Brings an archived plan back. A Free plan at its limit is refused with
  /// the usual limit message.
  Future<bool> restore(String planId) async {
    final failure = await _editor.unarchive(planId);
    if (!context.mounted) return failure == null;
    if (failure != null) {
      reportPlanFailure(context, failure);
      return false;
    }
    showAppToast(
      context,
      variant: AppToastVariant.success,
      title: 'Plan restored',
    );
    return true;
  }
}
