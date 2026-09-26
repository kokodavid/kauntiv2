import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/app_type_scale.dart';
import '../../../design/app_colors.dart';
import '../../../design/app_text_styles.dart';
import '../application/badges_providers.dart';
import '../domain/badge_collection.dart';
import 'badge_detail_sheet.dart';
import 'badge_grid_cell.dart';
import 'badges_hero_card.dart';

/// The Badges tab (Figma 491:1394): title and tier, how many of the 47
/// counties are claimed, and the collection of every county's badge with
/// its depth ring. Tapping a badge opens its sheet.
class BadgesScreen extends ConsumerWidget {
  const BadgesScreen({super.key, this.onOpenCounty, this.onOpenPlace});

  final OpenBadgeCounty? onOpenCounty;
  final OpenBadgePlace? onOpenPlace;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final collection = ref.watch(badgeCollectionProvider);
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: () => ref.refresh(badgeCollectionProvider.future),
          child: switch (collection) {
            AsyncValue(:final value?) => _Content(
              collection: value,
              onOpenCounty: onOpenCounty,
              onOpenPlace: onOpenPlace,
            ),
            AsyncValue(hasError: true) => const _Message(
              text: "Couldn't load your badges. Pull down to try again.",
            ),
            _ => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
          },
        ),
      ),
    );
  }
}

class _Content extends StatelessWidget {
  const _Content({
    required this.collection,
    this.onOpenCounty,
    this.onOpenPlace,
  });

  final BadgeCollection collection;
  final OpenBadgeCounty? onOpenCounty;
  final OpenBadgePlace? onOpenPlace;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          sliver: SliverList.list(
            children: [
              _Header(tier: collection.tier),
              const SizedBox(height: 14),
              BadgesHeroCard(collection: collection),
              const SizedBox(height: 20),
              Text(
                'ALL ${collection.total} COUNTIES',
                style: const TextStyle(
                  fontFamily: AppTypeScale.family,
                  fontSize: 12,
                  height: 20 / 12,
                  color: AppColors.accent,
                ),
              ),
              const Text('Collection', style: AppTextStyles.headingForeground),
              const SizedBox(height: 16),
            ],
          ),
        ),
        SliverPadding(
          // Room for the floating tab bar.
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
          sliver: SliverGrid.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: 14,
              crossAxisSpacing: 14,
            ),
            itemCount: collection.badges.length,
            itemBuilder: (context, i) {
              final badge = collection.badges[i];
              return BadgeGridCell(
                badge: badge,
                onTap: () => BadgeDetailSheet.show(
                  context,
                  badge: badge,
                  collection: collection,
                  onOpenCounty: onOpenCounty,
                  onOpenPlace: onOpenPlace,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.tier});

  final int tier;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          child: Text('Badges', style: AppTextStyles.headingForeground),
        ),
        if (tier > 0) _TierPill(tier: tier),
      ],
    );
  }
}

/// "Tier 2" with a medal (Figma 491:1400).
class _TierPill extends StatelessWidget {
  const _TierPill({required this.tier});

  final int tier;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 32,
      padding: const EdgeInsets.fromLTRB(6, 0, 10, 0),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.trackInactive),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.workspace_premium,
            size: 22,
            color: Color(0xFFD67D56),
          ),
          const SizedBox(width: 2),
          Text(
            'Tier $tier',
            style: const TextStyle(
              fontFamily: AppTypeScale.family,
              fontWeight: FontWeight.w500,
              fontSize: 12,
              height: 20 / 12,
              color: AppColors.mutedForeground,
            ),
          ),
        ],
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    // Scrollable so pull-to-refresh works.
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(24, 120, 24, 24),
      children: [
        Text(text, textAlign: TextAlign.center, style: AppTypeScale.body),
      ],
    );
  }
}
