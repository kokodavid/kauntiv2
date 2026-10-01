import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/domain/county_tier.dart';
import '../../../core/widgets/app_tier_medal.dart';
import '../../../design/app_colors.dart';
import '../../../design/app_text_styles.dart';
import '../../auth/application/auth_providers.dart';
import 'map_home_skeleton.dart';

part 'map_home_stat_card_parts.dart';

/// The outer card's border: Figma's slate-100 (#F1F5F9), a hair lighter
/// than the shared [AppColors.cardBorder] (slate-200) used elsewhere, so
/// it's kept local rather than changing that shared token.
const _outerBorder = Color(0xFFF1F5F9);

class MapHomeStatCard extends ConsumerWidget {
  const MapHomeStatCard({
    super.key,
    required this.exploredCount,
    required this.totalCounties,
    this.compact = false,
    this.tier,
    this.onOpenProfile,
  }) : loading = false;

  /// Placeholder shown while the board loads: same size as the real card,
  /// numbers masked and the tick bar pulsing. The avatar still shows (and
  /// still opens Profile if a handler is given) since the board loading
  /// shouldn't block getting there.
  const MapHomeStatCard.loading({super.key, this.onOpenProfile})
    : exploredCount = 0,
      totalCounties = 47,
      compact = false,
      tier = null,
      loading = true;

  final int exploredCount;
  final int totalCounties;

  /// Collapsed form shown while the map is being browsed (v1 parity): the
  /// numeral moves inline beside the tick bar and the caption drops out.
  final bool compact;
  final bool loading;

  /// The medal earned so far; none shows until the first (10 counties).
  /// Was the top bar's; the card now carries it alongside the avatar.
  final CountyTier? tier;

  /// Opens Profile from the avatar; the top bar no longer exists, so
  /// this is the only way in from Map Home.
  final VoidCallback? onOpenProfile;

  Widget _maskIfLoading(Widget child) =>
      loading ? MapHomeSkeletonMask(child: child) : child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final safeTotal = totalCounties <= 0 ? 1 : totalCounties;
    final percent = ((exploredCount / safeTotal) * 100).round();
    final left = (totalCounties - exploredCount).clamp(0, totalCounties);
    final ticks = _CountyTickBar(
      exploredCount: exploredCount,
      total: totalCounties,
    );
    final tickBar = loading ? MapHomeSkeletonPulse(child: ticks) : ticks;
    final trailing = _TrailingBadges(
      loading: loading,
      tier: tier,
      onOpenProfile: onOpenProfile,
    );
    final percentRow = [
      const SizedBox(height: 8),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _maskIfLoading(
            Text('$percent% OF KENYA', style: AppTextStyles.bodySmall),
          ),
          _maskIfLoading(Text('$left LEFT', style: AppTextStyles.bodySmall)),
        ],
      ),
    ];

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _outerBorder),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(40),
          topRight: Radius.circular(40),
          bottomLeft: Radius.circular(10),
          bottomRight: Radius.circular(10),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A606060),
            offset: Offset(0, 5),
            blurRadius: 23.5,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.fromLTRB(1, 0, 1, 0),
            // Just enough clearance to sit below the status bar/Dynamic
            // Island, not a full 16px on top of it — the numeral row was
            // sitting much further down than the design intends.
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFE6F3FF), Color(0x14DBEEFF)],
                stops: [0.02, 0.98],
              ),
              // Figma's inner panel only rounds its top corners (matching
              // the outer card); the bottom stays square since it sits
              // inside the card with the legend row below it.
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(40),
                topRight: Radius.circular(40),
              ),
            ),
            child: AnimatedSize(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              alignment: Alignment.topCenter,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: compact && !loading
                    ? [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  Text(
                                    '$exploredCount',
                                    style: AppTextStyles.statNumeralCompact,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(child: tickBar),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            trailing,
                          ],
                        ),
                        ...percentRow,
                      ]
                    : [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.baseline,
                                textBaseline: TextBaseline.alphabetic,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _maskIfLoading(
                                    Text(
                                      loading ? '00' : '$exploredCount',
                                      style: AppTextStyles.statNumeralCard,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Flexible(
                                    child: _maskIfLoading(
                                      Text(
                                        'of $totalCounties counties claimed',
                                        style: AppTextStyles.chipLabel,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            trailing,
                          ],
                        ),
                        const SizedBox(height: 6),
                        tickBar,
                        ...percentRow,
                      ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            child: _maskIfLoading(const _LegendRow()),
          ),
        ],
      ),
    );
  }
}

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

/// The signed-in user's initial in a circle, opening Profile.
class _ProfileAvatar extends ConsumerWidget {
  const _ProfileAvatar({this.onOpenProfile});

  final VoidCallback? onOpenProfile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(authUserIdProvider);
    final initial = ref.watch(authServiceProvider).currentUserInitial;
    return Tooltip(
      message: 'Profile',
      child: InkWell(
        onTap: onOpenProfile,
        customBorder: const CircleBorder(),
        child: Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: AppColors.accent,
            shape: BoxShape.circle,
          ),
          child: initial == null
              ? const Icon(Icons.person_outline, color: Colors.white, size: 18)
              : Text(
                  initial,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
        ),
      ),
    );
  }
}
