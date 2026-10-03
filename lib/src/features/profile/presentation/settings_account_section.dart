import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/services/app_external_links.dart';
import '../../journeys/domain/pro_status.dart';
import '../domain/public_profile.dart';
import 'settings_widgets.dart';

class SettingsAccountSection extends StatelessWidget {
  const SettingsAccountSection({
    super.key,
    required this.profile,
    required this.proStatus,
    required this.onOpenEditProfile,
    required this.onOpenMembership,
    required this.onOpenDataPrivacy,
    required this.onDeleteAccount,
  });

  final PublicProfile? profile;
  final ProStatus? proStatus;
  final VoidCallback onOpenEditProfile;
  final VoidCallback onOpenMembership;
  final VoidCallback onOpenDataPrivacy;
  final VoidCallback onDeleteAccount;

  Future<void> _openPrivacyPolicy() async {
    try {
      await AppExternalLinks.openPrivacyPolicy();
    } on Object {
      // Best effort external link; no in-app fallback.
    }
  }

  @override
  Widget build(BuildContext context) {
    final membershipSubtitle = proStatus?.active == true
        ? 'Pro · active'
        : 'Free';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SettingsSectionLabel('Account'),
        SettingsCard(
          children: [
            SettingsActionRow(
              title: 'Name, handle and photo',
              subtitle: profile == null
                  ? 'Set up your public identity'
                  : '${profile!.displayName} · @${profile!.handle}',
              onTap: onOpenEditProfile,
            ),
            SettingsActionRow(
              title: 'Membership',
              subtitle: membershipSubtitle,
              onTap: onOpenMembership,
              divider: true,
            ),
            SettingsActionRow(
              title: 'Data and privacy',
              subtitle: 'How county visits and Trips are stored',
              onTap: onOpenDataPrivacy,
              divider: true,
            ),
            SettingsActionRow(
              title: 'Privacy policy',
              subtitle: 'Opens kaunti47.com in your browser',
              onTap: () => unawaited(_openPrivacyPolicy()),
              trailing: const Icon(Icons.open_in_new, size: 18),
              divider: true,
            ),
            SettingsActionRow(
              title: 'Delete account',
              subtitle: 'Permanently remove your data',
              onTap: onDeleteAccount,
              danger: true,
              divider: true,
            ),
          ],
        ),
      ],
    );
  }
}
