import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../design/app_colors.dart';
import '../../auth/application/auth_providers.dart';
import '../../badges/application/badges_providers.dart';
import '../../detection/application/detection_controller.dart';
import '../../journeys/application/journey_entitlement.dart';
import '../../journeys/application/journey_recorder.dart';
import '../../onboarding/application/startup_flow.dart';
import '../application/public_profile_providers.dart';
import '../application/trip_stats_providers.dart';
import 'confirm_dialog.dart';
import 'edit_profile_sheet.dart';
import 'profile_county_badges.dart';
import 'profile_header.dart';
import 'profile_progress_card.dart';
import 'profile_tiles.dart';

/// A compact account overview. All account-bound values stay hidden until
/// the auth stream and the current Supabase user agree.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({
    super.key,
    required this.onOpenBadges,
    this.onOpenJourneys,
    required this.onOpenSettings,
  });

  final VoidCallback onOpenBadges;
  final VoidCallback? onOpenJourneys;

  /// Pushes the in-app Settings screen (architecture §2: cross-feature
  /// navigation goes through `app/router.dart`, not a direct import
  /// here). "Location permission", "Location diagnostics" and "Data and
  /// privacy" moved out of Profile and live only inside Settings now.
  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authUserIdProvider);
    final userId = auth.value;
    final user = ref.watch(authServiceProvider).currentUser;
    if (userId == null || user?.id != userId) {
      return Scaffold(
        backgroundColor: AppColors.pageBackground,
        body: Center(
          child: auth.hasError
              ? const Text('Could not load your account.')
              : auth.hasValue && userId == null
              ? const Text('Sign in to see your profile.')
              : const CircularProgressIndicator(),
        ),
      );
    }
    return _ProfileContent(
      key: ValueKey(userId),
      onOpenBadges: onOpenBadges,
      onOpenJourneys: onOpenJourneys,
      onOpenSettings: onOpenSettings,
    );
  }
}

class _ProfileContent extends ConsumerStatefulWidget {
  const _ProfileContent({
    super.key,
    required this.onOpenBadges,
    this.onOpenJourneys,
    required this.onOpenSettings,
  });

  final VoidCallback onOpenBadges;
  final VoidCallback? onOpenJourneys;
  final VoidCallback onOpenSettings;

  @override
  ConsumerState<_ProfileContent> createState() => _ProfileContentState();
}

class _ProfileContentState extends ConsumerState<_ProfileContent> {
  bool _checkingPro = true;
  bool _proUnavailable = false;
  bool _signingOut = false;

  @override
  void initState() {
    super.initState();
    unawaited(Future<void>.microtask(_refreshPro));
  }

  Future<void> _refreshPro() async {
    if (!mounted) return;
    setState(() {
      _checkingPro = true;
      _proUnavailable = false;
    });
    try {
      await ref.read(journeyEntitlementProvider.notifier).refreshStatus();
    } on Object {
      if (mounted) setState(() => _proUnavailable = true);
    } finally {
      if (mounted) setState(() => _checkingPro = false);
    }
  }

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

  void _openEditProfile() {
    final profile = ref.read(myPublicProfileProvider).value;
    if (profile == null) return;
    unawaited(
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        builder: (_) => EditProfileSheet(profile: profile),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authServiceProvider).currentUser;
    final metadata = user?.userMetadata ?? const <String, dynamic>{};
    final rawName = metadata['full_name'] ?? metadata['name'];
    final fallbackName = rawName is String ? rawName : null;
    final homeCounty = ref.watch(startupFlowProvider).homeCounty?.name;
    final badges = ref.watch(badgeCollectionProvider);
    final tripStats = ref.watch(tripStatsProvider);
    final publicProfile = ref.watch(myPublicProfileProvider).value;
    final pro = ref.watch(journeyEntitlementProvider);
    final isPro = pro?.allowsStartAt(DateTime.now()) == true;
    final proLabel = _checkingPro
        ? 'Checking access...'
        : _proUnavailable
        ? "Couldn't check. Tap to retry."
        : isPro
        ? 'Pro active'
        : 'Free';
    final displayName = publicProfile?.displayName.isNotEmpty == true
        ? publicProfile!.displayName
        : (fallbackName?.isNotEmpty == true ? fallbackName! : 'Traveller');

    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      body: SafeArea(
        top: false,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            ProfileHeader(
              name: displayName,
              handle: publicProfile?.handle,
              avatarUrl: publicProfile?.avatarUrl,
              homeCounty: homeCounty,
              isPro: isPro,
              onOpenSettings: widget.onOpenSettings,
              onEditProfile: _openEditProfile,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ProfileProgressCard(
                    collection: badges,
                    onRetry: () => ref.invalidate(badgeCollectionProvider),
                    tripStats: tripStats,
                  ),
                  const SizedBox(height: 14),
                  ProfileCountyBadges(
                    collection: badges,
                    onOpenBadges: widget.onOpenBadges,
                  ),
                  const SizedBox(height: 14),
                  ProfileTile(
                    icon: Icons.workspace_premium_outlined,
                    title: 'Kaunti47 Pro',
                    subtitle: proLabel,
                    style: ProfileTileStyle.dark,
                    onTap: _proUnavailable
                        ? () => unawaited(_refreshPro())
                        : null,
                  ),
                  if (widget.onOpenJourneys != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 14),
                      child: ProfileTile(
                        icon: Icons.route_outlined,
                        title: 'Trips',
                        subtitle: 'Your private recorded routes',
                        style: ProfileTileStyle.surface,
                        onTap: widget.onOpenJourneys,
                      ),
                    ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: _signingOut ? null : () => unawaited(_signOut()),
                    icon: const Icon(Icons.logout),
                    label: Text(_signingOut ? 'Signing out...' : 'Sign out'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.foreground,
                      side: const BorderSide(color: ProfilePalette.border),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
