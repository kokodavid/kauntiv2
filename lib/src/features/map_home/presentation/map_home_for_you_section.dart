import 'package:flutter/material.dart';

import '../../../core/design/app_type_scale.dart';
import '../../../design/app_colors.dart';
import '../domain/map_home_models.dart';
import 'map_home_featured_suggestion.dart';
import 'map_home_links.dart';
import 'map_home_skeleton.dart';
import 'map_home_unclaimed_card.dart';

/// Home's For You (Figma "Your next best move"): the promoted place (or,
/// when nothing is promoted, the best suggestion) as the top card, then a
/// row of the nearest unclaimed counties with "All N left".
class MapHomeForYouSection extends StatelessWidget {
  const MapHomeForYouSection({
    super.key,
    required this.data,
    this.onOpenCounty,
    this.onOpenPlace,
    this.onRoute,
    this.onSeeAllUnclaimed,
  });

  final MapHomeBoardData data;
  final OpenCountyDetail? onOpenCounty;
  final OpenPlaceDetail? onOpenPlace;

  /// Opens directions for the Route buttons; they're hidden when null.
  final OpenDirections? onRoute;
  final OpenAllUnclaimed? onSeeAllUnclaimed;

  @override
  Widget build(BuildContext context) {
    final promotion = data.promotion;
    final fallback = data.fallbackTop;
    final row = data.unclaimedRow;
    final seeAll = onSeeAllUnclaimed;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (promotion != null || fallback != null) ...[
          const MapHomeForYouHeader(),
          const SizedBox(height: 10),
          if (promotion != null)
            MapHomeFeatureCard.promotion(
              promotion,
              onOpenPlace: onOpenPlace,
              onOpenCounty: onOpenCounty,
              onRoute: onRoute,
            )
          else
            MapHomeFeatureCard.suggestion(
              fallback!,
              onOpenCounty: onOpenCounty,
              onRoute: onRoute,
            ),
        ],
        if (row.isNotEmpty) ...[
          const SizedBox(height: 20),
          _SectionHeading(
            kicker: 'NEXT FOR YOU',
            title: 'Nearby and unclaimed',
            trailing: seeAll == null
                ? null
                : _SeeAll(
                    label: 'All ${data.unclaimedCount} left',
                    onTap: () => seeAll(context),
                  ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 184,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              itemCount: row.length,
              separatorBuilder: (context, index) => const SizedBox(width: 10),
              itemBuilder: (context, index) => MapHomeUnclaimedCard(
                suggestion: row[index],
                onOpenCounty: onOpenCounty,
                onRoute: onRoute,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// "PRIMARY TARGET / Your next best move".
class MapHomeForYouHeader extends StatelessWidget {
  const MapHomeForYouHeader({super.key});

  @override
  Widget build(BuildContext context) => const _SectionHeading(
    kicker: 'PRIMARY TARGET',
    title: 'Your next best move',
  );
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({
    required this.kicker,
    required this.title,
    this.trailing,
  });

  final String kicker;
  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                kicker,
                style: AppTypeScale.sectionLabel.copyWith(
                  color: AppColors.accent,
                ),
              ),
              const SizedBox(height: 2),
              Text(title, style: AppTypeScale.sectionTitle),
            ],
          ),
        ),
        ?trailing,
      ],
    );
  }
}

class _SeeAll extends StatelessWidget {
  const _SeeAll({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: AppTypeScale.small),
            const Icon(
              Icons.chevron_right,
              size: 16,
              color: AppColors.mutedForeground,
            ),
          ],
        ),
      ),
    );
  }
}

/// Loading placeholder shaped like the top card.
class MapHomeForYouSkeleton extends StatelessWidget {
  const MapHomeForYouSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const MapHomeForYouHeader(),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: AppColors.cardBorder),
            borderRadius: BorderRadius.circular(24),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              MapHomeSkeletonBlock(height: 136, radius: 20),
              Padding(
                padding: EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    MapHomeSkeletonBlock(width: 180, height: 16),
                    SizedBox(height: 12),
                    MapHomeSkeletonBlock(width: 220, height: 12),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
