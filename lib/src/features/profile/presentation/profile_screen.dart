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
import 'profile_header.dart';
import 'profile_privacy_sheet.dart';
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
  final Future<void> Function() onOpenSettings;

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
  final Future<void> Function() onOpenSettings;

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
          content: Text('Finish or discard your active Journey before signing out.'),
        ),
      );
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text(
          'Your Journeys stay on this phone. Synced Journeys will also be '
          'available when you sign in again.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
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
    final user = ref.watch(authServiceProvider).currentUser;
    final metadata = user?.userMetadata ?? const <String, dynamic>{};
    final rawName = metadata['full_name'] ?? metadata['name'];
    final name = rawName is String ? rawName : null;
    final email = user?.email?.isNotEmpty == true
        ? user!.email!
        : 'No email on this account';
    final homeCounty = ref.watch(startupFlowProvider).homeCounty?.name;
    final badges = ref.watch(badgeCollectionProvider);
    final pro = ref.watch(journeyEntitlementProvider);
    final proLabel = _checkingPro
        ? 'Checking access...'
        : _proUnavailable
        ? "Couldn't check. Tap to retry."
        : pro?.allowsStartAt(DateTime.now()) == true
        ? 'Pro active'
        : 'Free';

    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: ProfilePalette.surface,
        foregroundColor: AppColors.foreground,
        elevation: 0,
      ),
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            ProfileHeader(
              name: name?.isNotEmpty == true ? name! : 'Traveller',
              email: email,
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const ProfileSectionTitle('Your progress'),
                  ProfileTile(
                    icon: Icons.home_outlined,
                    title: 'Home county',
                    subtitle: homeCounty ?? 'Not selected',
                  ),
                  ProfileTile(
                    icon: Icons.workspace_premium_outlined,
                    title: 'County badges',
                    subtitle: badges.when(
                      loading: () => 'Loading...',
                      error: (_, __) => 'Unable to load',
                      data: (value) => '${value.claimed} of ${value.total} earned',
                    ),
                    onTap: widget.onOpenBadges,
                  ),
                  if (widget.onOpenJourneys != null)
                    ProfileTile(
                      icon: Icons.route_outlined,
                      title: 'Journeys',
                      subtitle: 'Your private recorded routes',
                      onTap: widget.onOpenJourneys,
                    ),
                  const SizedBox(height: 24),
                  const ProfileSectionTitle('Account'),
                  ProfileTile(
                    icon: Icons.stars_outlined,
                    title: 'Membership',
                    subtitle: proLabel,
                    onTap: _proUnavailable
                        ? () => unawaited(_refreshPro())
                        : null,
                  ),
                  ProfileTile(
                    icon: Icons.location_on_outlined,
                    title: 'Location permission',
                    subtitle: 'Manage in device settings',
                    onTap: () => unawaited(widget.onOpenSettings()),
                  ),
                  ProfileTile(
                    icon: Icons.shield_outlined,
                    title: 'Data and privacy',
                    subtitle: 'How county visits and Journeys are stored',
                    onTap: () => unawaited(
                      showModalBottomSheet<void>(
                        context: context,
                        isScrollControlled: true,
                        builder: (_) => const ProfilePrivacySheet(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: _signingOut ? null : () => unawaited(_signOut()),
                    icon: const Icon(Icons.logout),
                    label: Text(_signingOut ? 'Signing out...' : 'Sign out'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.accent,
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
