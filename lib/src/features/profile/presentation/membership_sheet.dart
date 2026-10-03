import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../design/app_colors.dart';
import '../../journeys/domain/pro_status.dart';

/// Pro details, reached from Profile's Pro tile and Settings' Membership
/// row. Billing doesn't exist yet (security plan: periods are granted by
/// admins until tracker #12), so "Manage" just opens the OS's own
/// subscription-management screen -- there is nothing in-app to manage.
class MembershipSheet extends StatelessWidget {
  const MembershipSheet({super.key, required this.status});

  final ProStatus? status;

  static const _features = [
    'Offline county maps',
    'Full journey replay & share cards',
    'Unlimited Trip history',
  ];

  Future<void> _manageSubscription() async {
    final uri = Platform.isIOS
        ? Uri.parse('itms-apps://apps.apple.com/account/subscriptions')
        : Uri.parse('https://play.google.com/store/account/subscriptions');
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } on Object {
      // Best effort: no in-app fallback exists for subscription management.
    }
  }

  @override
  Widget build(BuildContext context) {
    final active = status?.active == true;
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
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: active ? const Color(0xFFDCFCE7) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    active ? 'Active' : 'Free',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: active ? const Color(0xFF15803D) : AppColors.mutedForeground,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              active
                  ? (until == null
                        ? 'Active'
                        : 'Renews ${_formatDate(until)}')
                  : 'Upgrade to unlock everything below.',
              style: const TextStyle(color: AppColors.mutedForeground),
            ),
            const SizedBox(height: 16),
            for (final feature in _features)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, size: 18, color: AppColors.accent),
                    const SizedBox(width: 10),
                    Expanded(child: Text(feature)),
                  ],
                ),
              ),
            const SizedBox(height: 10),
            if (active)
              OutlinedButton(
                onPressed: () => unawaited(_manageSubscription()),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.accent,
                  side: const BorderSide(color: AppColors.accent),
                  minimumSize: const Size.fromHeight(48),
                ),
                child: Text(Platform.isIOS ? 'Manage in App Store' : 'Manage in Google Play'),
              ),
          ],
        ),
      ),
    );
  }
}

const _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

String _formatDate(DateTime date) =>
    '${date.day} ${_months[date.month - 1]} ${date.year}';
