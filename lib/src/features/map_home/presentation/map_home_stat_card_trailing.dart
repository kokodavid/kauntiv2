part of 'map_home_stat_card.dart';

/// The tier medal and the profile avatar, top-right of the card (the top
/// bar used to hold these; now the card does, matching the merged-header
/// design where everything sits in one card near the top of the screen).
class _TrailingBadges extends StatelessWidget {
  const _TrailingBadges({
    required this.loading,
    required this.tier,
    this.onOpenProfile,
  });

  final bool loading;
  final CountyTier? tier;
  final VoidCallback? onOpenProfile;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          child: loading
              ? const _MedalPlaceholder(key: ValueKey('loading'))
              : tier == null
              ? const SizedBox.shrink(key: ValueKey('none'))
              : Padding(
                  key: ValueKey(tier),
                  padding: const EdgeInsets.only(right: 8),
                  child: AppTierPill(tier: tier!),
                ),
        ),
        _ProfileAvatar(onOpenProfile: onOpenProfile),
      ],
    );
  }
}

class _MedalPlaceholder extends StatelessWidget {
  const _MedalPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(right: 8),
      child: MapHomeSkeletonMask(
        child: Text('Mzururaji', style: AppTextStyles.chipLabel),
      ),
    );
  }
}

/// The signed-in user's profile picture in a circle (their initial until
/// they have one), opening Profile. Reads the same public profile as the
/// Profile screen, so a new picture shows here as soon as it is saved.
class _ProfileAvatar extends ConsumerWidget {
  const _ProfileAvatar({this.onOpenProfile});

  final VoidCallback? onOpenProfile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(authUserIdProvider);
    final initial = ref.watch(authServiceProvider).currentUserInitial;
    final avatarUrl = ref.watch(myPublicProfileProvider).value?.avatarUrl;
    final hasPicture = avatarUrl != null && avatarUrl.isNotEmpty;
    return Tooltip(
      message: 'Profile',
      child: InkWell(
        onTap: onOpenProfile,
        customBorder: const CircleBorder(),
        // A blue ring with a small white gap, so the picture (or initial)
        // reads as one badge on the pale card.
        child: Container(
          width: 36,
          height: 36,
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.accent, width: 2),
          ),
          child: Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.accent,
              shape: BoxShape.circle,
              image: hasPicture
                  ? DecorationImage(
                      image: appNetworkImage(avatarUrl, cacheWidth: 96),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: hasPicture
                ? null
                : initial == null
                ? const Icon(
                    Icons.person_outline,
                    color: Colors.white,
                    size: 16,
                  )
                : Text(
                    initial,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
