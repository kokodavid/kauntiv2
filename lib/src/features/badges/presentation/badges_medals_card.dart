import 'package:flutter/material.dart';

import '../../../core/design/app_type_scale.dart';
import '../../../core/domain/county_tier.dart';
import '../../../core/widgets/app_tier_medal.dart';
import '../../../design/app_colors.dart';
import 'badges_hero_card.dart';

/// The three medals side by side. Tapping the footer expands how far the
/// user is from the next one, each medal's status, and how counties are
/// claimed.
class BadgesMedalsCard extends StatefulWidget {
  const BadgesMedalsCard({super.key, required this.claimed});

  /// Counties claimed so far.
  final int claimed;

  @override
  State<BadgesMedalsCard> createState() => _BadgesMedalsCardState();
}

class _BadgesMedalsCardState extends State<BadgesMedalsCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final claimed = widget.claimed;
    final next = CountyTier.nextAfter(claimed);
    return BadgesCardShell(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Text(
              'Tiers',
              style: TextStyle(
                fontFamily: AppTypeScale.family,
                fontWeight: FontWeight.w600,
                fontSize: 16,
                height: 24 / 16,
                color: AppColors.foreground,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 10, 8, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final tier in CountyTier.values)
                  Expanded(child: _Medal(tier: tier)),
              ],
            ),
          ),
          // Inset: doesn't run to the card's edges.
          const Divider(
            height: 1,
            indent: 16,
            endIndent: 16,
            color: AppColors.listDivider,
          ),
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      next == null
                          ? 'All three medals earned'
                          : 'Next: ${next.label}',
                      style: _body,
                    ),
                  ),
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(
                      Icons.keyboard_arrow_down,
                      color: AppColors.mutedForeground,
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: _expanded
                ? _Progress(claimed: claimed, next: next)
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }
}

const _small = TextStyle(
  fontFamily: AppTypeScale.family,
  fontSize: 12,
  height: 18 / 12,
  color: AppColors.mutedForeground,
);

const _body = TextStyle(
  fontFamily: AppTypeScale.family,
  fontWeight: FontWeight.w500,
  fontSize: 14,
  height: 20 / 14,
  color: AppColors.foreground,
);

class _Medal extends StatelessWidget {
  const _Medal({required this.tier});

  final CountyTier tier;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AppTierMedal(tier: tier, height: 48),
        const SizedBox(height: 4),
        Text(
          tier.label,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: _body.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: 12,
            height: 16 / 12,
          ),
        ),
      ],
    );
  }
}

/// One medal's line in the expanded part: what it takes and its status.
class _TierLine extends StatelessWidget {
  const _TierLine({
    required this.tier,
    required this.claimed,
    required this.isNext,
  });

  final CountyTier tier;
  final int claimed;
  final bool isNext;

  @override
  Widget build(BuildContext context) {
    final earned = claimed >= tier.counties;
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '${tier.label} · ${tier.counties} counties',
              style: _small.copyWith(color: AppColors.foreground),
            ),
          ),
          if (earned)
            const _Status(
              icon: Icons.check_circle,
              color: AppColors.legendHome,
              text: 'Earned',
            )
          else if (isNext)
            Text(
              '${tier.counties - claimed} to go',
              style: _small.copyWith(
                fontWeight: FontWeight.w500,
                color: AppColors.accent,
              ),
            )
          else
            _Status(
              icon: Icons.lock_outline,
              color: AppColors.lockedStroke,
              text: '${tier.counties - claimed} more',
            ),
        ],
      ),
    );
  }
}

class _Status extends StatelessWidget {
  const _Status({required this.icon, required this.color, required this.text});

  final IconData icon;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(text, style: _small),
      ],
    );
  }
}

/// The expanded part: progress to the next medal, each medal's status,
/// and how a county is claimed.
class _Progress extends StatelessWidget {
  const _Progress({required this.claimed, required this.next});

  final int claimed;
  final CountyTier? next;

  @override
  Widget build(BuildContext context) {
    final next = this.next;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (next != null) ...[
            Row(
              children: [
                Expanded(
                  child: Text(
                    '$claimed of ${next.counties} counties',
                    style: _small.copyWith(color: AppColors.foreground),
                  ),
                ),
                Text(
                  '${next.counties - claimed} to go',
                  style: _small.copyWith(color: AppColors.accent),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: (claimed / next.counties).clamp(0, 1).toDouble(),
                minHeight: 6,
                color: AppColors.accent,
                backgroundColor: AppColors.trackInactive,
              ),
            ),
            const SizedBox(height: 4),
          ],
          for (final tier in CountyTier.values)
            _TierLine(tier: tier, claimed: claimed, isNext: tier == next),
          const SizedBox(height: 14),
          const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.only(top: 1),
                child: Icon(
                  Icons.info_outline,
                  size: 16,
                  color: AppColors.mutedForeground,
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Claim a county by spending about 2 hours in it. '
                  "Passing through doesn't count.",
                  style: _small,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
