import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/app_external_links.dart';
import '../../../design/app_colors.dart';
import '../../billing/application/billing_providers.dart';
import '../../billing/domain/pro_features.dart';
import '../../journeys/domain/pro_status.dart';

/// Opens the Membership sheet for [status].
Future<void> showMembershipSheet(
  BuildContext context,
  ProStatus status, {
  VoidCallback? onUpgrade,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  builder: (_) => MembershipSheet(status: status, onUpgrade: onUpgrade),
);

/// Pro details, reached from Profile's Pro tile and Settings' Membership
/// row. Free accounts get an Upgrade button while the dashboard's billing
/// switch is on; "Manage" opens the OS's own subscription-management
/// screen, since the store owns changes and cancellation.
class MembershipSheet extends ConsumerWidget {
  const MembershipSheet({super.key, required this.status, this.onUpgrade});

  final ProStatus? status;

  /// Opens the purchase screen; null hides the Upgrade button.
  final VoidCallback? onUpgrade;

  Future<void> _manageSubscription() async {
    try {
      await AppExternalLinks.manageSubscription();
    } on Object {
      // Best effort: no in-app fallback exists for subscription management.
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final active = status?.active == true;
    final canUpgrade =
        !active && onUpgrade != null && ref.watch(billingAvailableProvider);
    final until = status?.activeUntil;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Text(
                  'Kaunti47 Pro',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: active
                        ? const Color(0xFFDCFCE7)
                        : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    active ? 'Active' : 'Free',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: active
                          ? const Color(0xFF15803D)
                          : AppColors.mutedForeground,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              active
                  ? (until == null ? 'Active' : 'Renews ${_formatDate(until)}')
                  : 'Upgrade to unlock everything below.',
              style: const TextStyle(color: AppColors.mutedForeground),
            ),
            const SizedBox(height: 16),
            for (final feature in ProFeatures.list)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    const Icon(
                      Icons.check_circle,
                      size: 18,
                      color: AppColors.accent,
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: Text(feature)),
                  ],
                ),
              ),
            const SizedBox(height: 10),
            if (canUpgrade)
              FilledButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  onUpgrade?.call();
                },
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: AppColors.accentForeground,
                  minimumSize: const Size.fromHeight(48),
                ),
                child: const Text('Upgrade to Pro'),
              ),
            if (active)
              OutlinedButton(
                onPressed: () => unawaited(_manageSubscription()),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.accent,
                  side: const BorderSide(color: AppColors.accent),
                  minimumSize: const Size.fromHeight(48),
                ),
                child: Text(
                  'Manage in ${AppExternalLinks.subscriptionStoreName}',
                ),
              ),
          ],
        ),
      ),
    );
  }
}

const _months = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

String _formatDate(DateTime date) =>
    '${date.day} ${_months[date.month - 1]} ${date.year}';
