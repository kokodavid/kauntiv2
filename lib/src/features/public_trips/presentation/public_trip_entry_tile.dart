import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/app_confirm_sheet.dart';
import '../../../core/widgets/app_floating_toast.dart';
import '../../../design/app_colors.dart';
import '../../../design/app_text_styles.dart';
import '../application/public_trip_providers.dart';
import '../domain/public_trip_failure.dart';
import '../domain/public_trip_owner_view.dart';
import 'public_trip_status_chip.dart';

/// The "make this trip public" row in the Share trip sheet, and its state
/// once the trip has been submitted. Hidden when public trips are off or
/// the trip cannot be published. [onOpen] opens the review screen; the app
/// wires navigation, so this widget never knows about routes.
class PublicTripEntryTile extends ConsumerWidget {
  const PublicTripEntryTile({
    super.key,
    required this.journeyId,
    required this.onOpen,
    this.onView,
    this.canPublish = true,
  });

  final String journeyId;
  final VoidCallback onOpen;

  /// Opens the live public page, as other people see it; hidden when null.
  final void Function(String publicationId)? onView;

  /// False for a trip that is not uploaded yet or has no drive/walk mode.
  final bool canPublish;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enabled = ref.watch(publicTripPublishingEnabledProvider).value;
    final mine = ref.watch(myPublicTripProvider(journeyId));
    final view = mine.value;
    // Someone who already has a public copy keeps seeing its state (and the
    // withdraw action) even if new submissions are switched off.
    final hasCopy = view != null && view.phase != PublicTripPhase.none;
    if (!hasCopy && (enabled != true || !canPublish)) {
      return const SizedBox.shrink();
    }
    if (mine.isLoading && !mine.hasValue) return const SizedBox.shrink();
    final phase = view?.phase ?? PublicTripPhase.none;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.public, color: AppColors.accent, size: 22),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Public trip',
                      style: AppTextStyles.listItemTitle,
                    ),
                  ),
                  PublicTripStatusChip(phase: phase),
                ],
              ),
              const SizedBox(height: 6),
              Text(_subtitle(view, phase), style: AppTextStyles.bodySmall),
              const SizedBox(height: 10),
              _actions(context, ref, view, phase),
            ],
          ),
        ),
      ),
    );
  }

  String _subtitle(PublicTripOwnerView? view, PublicTripPhase phase) =>
      switch (phase) {
        PublicTripPhase.none =>
          'Share the route with other Kaunti47 users. A moderator reviews it first and the start and end stay hidden.',
        PublicTripPhase.awaitingReview =>
          'A moderator will review it soon. It is not visible to anyone yet.',
        PublicTripPhase.isPublic =>
          view != null && view.hasPendingChange
              ? 'Live now. Your change is waiting for review.'
              : 'Other Kaunti47 users can see this trip.',
        PublicTripPhase.needsChanges => _changesText(view?.reviewReason),
        PublicTripPhase.hidden =>
          'A moderator hid this trip. It is not visible to anyone.',
      };

  static String _changesText(String? reason) =>
      reason == null || reason.isEmpty
      ? 'A moderator asked for changes.'
      : 'A moderator asked for changes: $reason';

  Widget _actions(
    BuildContext context,
    WidgetRef ref,
    PublicTripOwnerView? view,
    PublicTripPhase phase,
  ) {
    final publishingOn = ref.watch(publicTripPublishingEnabledProvider).value;
    final canEdit = publishingOn == true && canPublish;
    final buttons = <Widget>[
      if (phase == PublicTripPhase.none && canEdit)
        _TileButton(label: 'Make public', primary: true, onTap: onOpen),
      if (phase == PublicTripPhase.needsChanges && canEdit)
        _TileButton(label: 'Edit and resubmit', primary: true, onTap: onOpen),
      if (phase == PublicTripPhase.isPublic && view != null && onView != null)
        _TileButton(label: 'View', primary: true, onTap: () => onView!(view.id)),
      if (phase == PublicTripPhase.isPublic && canEdit)
        _TileButton(label: 'Edit', onTap: onOpen),
      if (view != null &&
          (phase == PublicTripPhase.awaitingReview ||
              phase == PublicTripPhase.isPublic ||
              phase == PublicTripPhase.needsChanges))
        _TileButton(
          label: phase == PublicTripPhase.isPublic ? 'Withdraw' : 'Cancel',
          onTap: () => unawaited(_withdraw(context, ref, view)),
        ),
    ];
    if (buttons.isEmpty) return const SizedBox.shrink();
    return Wrap(spacing: 8, runSpacing: 8, children: buttons);
  }

  Future<void> _withdraw(
    BuildContext context,
    WidgetRef ref,
    PublicTripOwnerView view,
  ) async {
    final live = view.phase == PublicTripPhase.isPublic;
    final confirmed = await showAppConfirmSheet(
      context,
      icon: Icons.public_off,
      iconColor: AppColors.danger,
      iconTint: AppColors.danger.withValues(alpha: 0.12),
      title: live ? 'Withdraw this trip?' : 'Cancel this submission?',
      body: live
          ? 'It disappears for everyone straight away. Your private trip is not affected.'
          : 'It will not be reviewed or shown. Your private trip is not affected.',
      primaryLabel: live ? 'Withdraw' : 'Cancel submission',
      primaryColor: AppColors.danger,
      secondaryLabel: 'Keep it',
    );
    if (!confirmed || !context.mounted) return;
    try {
      await ref
          .read(publicTripWithdrawalProvider(journeyId).notifier)
          .withdraw(view.id);
    } on PublicTripFailure catch (failure) {
      if (!context.mounted) return;
      showAppToast(
        context,
        variant: AppToastVariant.error,
        title: "Couldn't withdraw the trip",
        message: failure.message,
      );
    }
  }
}

class _TileButton extends StatelessWidget {
  const _TileButton({
    required this.label,
    required this.onTap,
    this.primary = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        backgroundColor: primary ? AppColors.accent : AppColors.secondaryFill,
        foregroundColor: primary ? AppColors.accentForeground : AppColors.foreground,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Text(label, style: AppTextStyles.buttonLabelSecondary.copyWith(
        color: primary ? AppColors.accentForeground : AppColors.foreground,
      )),
    );
  }
}
