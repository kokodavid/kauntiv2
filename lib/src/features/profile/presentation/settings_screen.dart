import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/app_back_button.dart';
import '../../../design/app_colors.dart';
import '../../../widgets/app_progress_indicator.dart';
import '../../auth/application/auth_providers.dart';
import '../../detection/application/detection_controller.dart';
import '../../journeys/application/journey_entitlement.dart';
import '../../journeys/application/journey_recorder.dart';
import '../../onboarding/application/startup_flow.dart';
import '../../public_trips/application/public_trip_providers.dart';
import '../application/profile_settings_providers.dart';
import '../application/public_profile_providers.dart';
import 'confirm_dialog.dart';
import 'delete_account_dialog.dart';
import 'edit_profile_sheet.dart';
import 'membership_sheet.dart';
import 'profile_privacy_sheet.dart';
import 'settings_account_section.dart';
import 'settings_developer_section.dart';
import 'settings_location_section.dart';
import 'settings_notifications_section.dart';
import 'settings_widgets.dart';

/// Settings, reached from Profile's gear button. Everything that used to
/// be inline Profile tiles ("Location permission") now lives here,
/// alongside the preference columns `profiles` already had but no screen
/// ever surfaced (map visibility, notifications, side-quest radius,
/// location mode).
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({
    super.key,
    required this.onOpenLocationSettings,
    this.onOpenLocationDiagnostics,
    this.onOpenPublicTripDefaults,
  });

  final Future<void> Function() onOpenLocationSettings;
  final VoidCallback? onOpenLocationDiagnostics;

  /// Opens the public-trip share defaults; shown only while public trips
  /// are switched on.
  final VoidCallback? onOpenPublicTripDefaults;

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _signingOut = false;

  Future<void> _signOut() async {
    if (ref.read(journeyRecorderProvider) != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Finish or discard your active Trip before signing out.',
          ),
        ),
      );
      return;
    }
    final confirmed = await showStackedConfirmDialog(
      context,
      title: 'Sign out of Kaunti47?',
      body:
          'County detection pauses on this phone until you sign back in. '
          'Synced badges and Trips stay on your account.',
      primaryLabel: 'Sign out',
      primaryColor: AppColors.foreground,
    );
    if (!confirmed || !mounted) return;
    setState(() => _signingOut = true);
    final startup = ref.read(startupFlowProvider.notifier);
    final auth = ref.read(authServiceProvider);
    final detection = ref.read(detectionControllerProvider.notifier);
    try {
      await detection.suspendForSignOut();
      await auth.signOut();
      startup.resetAfterSignOut();
    } on Object {
      detection.resumeAfterSignOutFailure();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Couldn't sign out. Try again.")),
        );
      }
    } finally {
      if (mounted) setState(() => _signingOut = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(profileSettingsControllerProvider);
    final profileAsync = ref.watch(myPublicProfileProvider);
    final proStatus = ref.watch(journeyEntitlementProvider);
    final controller = ref.read(profileSettingsControllerProvider.notifier);
    final notifier = (
      setMapVisibility: controller.setMapVisibility,
      setShowOnLeaderboards: controller.setShowOnLeaderboards,
      setNotifyBadgeUnlocks: controller.setNotifyBadgeUnlocks,
      setNotifyCountyNudges: controller.setNotifyCountyNudges,
      setSideQuestRadiusKm: controller.setSideQuestRadiusKm,
      setLocationMode: controller.setLocationMode,
    );

    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        ),
        centerTitle: false,
        titleSpacing: 12,
        backgroundColor: AppColors.pageBackground,
        foregroundColor: AppColors.foreground,
        elevation: 0,
        leadingWidth: 68,
        // AppBar gives `leading` a *tight* box (leadingWidth x toolbar
        // height), unlike the loose boxes AppBackButton sits in
        // everywhere else (a Row, a Stack/Align) -- without this Align,
        // that tight box stretches the button past its own 40x40 size.
        // Align hands its child loose constraints instead, so the
        // button's own fixed size wins here too.
        leading: Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: const EdgeInsets.only(left: 16),
            child: AppBackButton(
              onPressed: () => Navigator.of(context).maybePop(),
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: settingsAsync.when(
          loading: () => const Center(
            child: AppProgressIndicator(color: AppColors.accent, radius: 14),
          ),
          error: (error, stackTrace) => Center(
            child: TextButton(
              onPressed: () =>
                  ref.invalidate(profileSettingsControllerProvider),
              child: const Text('Settings are unavailable. Retry.'),
            ),
          ),
          data: (settings) => ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
            children: [
              // Privacy and Side Quests sections are hidden for now (not
              // removed -- `settings_privacy_section.dart` and
              // `settings_side_quests_section.dart` are still there to
              // bring back).
              SettingsNotificationsSection(
                settings: settings,
                notifier: notifier,
              ),
              const SizedBox(height: 18),
              SettingsLocationSection(
                settings: settings,
                notifier: notifier,
                onOpenLocationSettings: () =>
                    unawaited(widget.onOpenLocationSettings()),
              ),
              const SizedBox(height: 18),
              if (widget.onOpenPublicTripDefaults != null &&
                  (ref.watch(publicTripPublishingEnabledProvider).value ??
                      false)) ...[
                const SettingsSectionLabel('Public trips'),
                SettingsCard(
                  children: [
                    SettingsActionRow(
                      title: 'Share defaults',
                      subtitle:
                          'What starts switched on when you make a trip public',
                      onTap: widget.onOpenPublicTripDefaults,
                    ),
                  ],
                ),
                const SizedBox(height: 18),
              ],
              SettingsAccountSection(
                profile: profileAsync.value,
                proStatus: proStatus,
                onOpenEditProfile: () {
                  final profile = profileAsync.value;
                  if (profile == null) return;
                  unawaited(
                    showModalBottomSheet<void>(
                      context: context,
                      isScrollControlled: true,
                      builder: (_) => EditProfileSheet(profile: profile),
                    ),
                  );
                },
                onOpenMembership: () => unawaited(
                  showModalBottomSheet<void>(
                    context: context,
                    isScrollControlled: true,
                    builder: (_) => MembershipSheet(status: proStatus),
                  ),
                ),
                onOpenDataPrivacy: () => unawaited(
                  showModalBottomSheet<void>(
                    context: context,
                    isScrollControlled: true,
                    builder: (_) => const ProfilePrivacySheet(),
                  ),
                ),
                onDeleteAccount: () =>
                    unawaited(showDeleteAccountDialog(context, ref)),
              ),
              const SizedBox(height: 18),
              SettingsDeveloperSection(
                onOpenLocationDiagnostics: widget.onOpenLocationDiagnostics,
              ),
              const SizedBox(height: 4),
              OutlinedButton.icon(
                onPressed: _signingOut ? null : () => unawaited(_signOut()),
                icon: const Icon(Icons.logout),
                label: Text(_signingOut ? 'Signing out...' : 'Sign out'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.accent,
                  side: const BorderSide(color: Color(0xFFD5E7FA)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
