import 'package:flutter/material.dart';

import '../../../design/app_colors.dart';
import '../domain/map_home_models.dart';
import 'map_home_featured_suggestion.dart';
import 'map_home_links.dart';
import 'map_home_primary_button.dart';
import 'map_home_section_heading.dart';
import 'map_home_skeleton.dart';
import 'map_home_unclaimed_card.dart';

/// "PRIMARY TARGET / Your next best move": the promoted place, or when
/// nothing is promoted the best suggestion. Hides when there is neither.
class MapHomePrimaryTarget extends StatelessWidget {
  const MapHomePrimaryTarget({
    super.key,
    required this.data,
    this.kicker = 'PRIMARY TARGET',
    this.title = 'Your next best move',
    this.onOpenCounty,
    this.onOpenPlace,
    this.onRoute,
    this.onPromotedPlaceRoute,
  });

  final MapHomeBoardData data;
  final String kicker;
  final String title;
  final OpenCountyDetail? onOpenCounty;
  final OpenPlaceDetail? onOpenPlace;
  final OpenDirections? onRoute;
  final OpenPromotedPlaceDirections? onPromotedPlaceRoute;

  @override
  Widget build(BuildContext context) {
    final promotion = data.promotion;
    final fallback = data.fallbackTop;
    if (promotion == null && fallback == null) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MapHomeSectionHeading(kicker: kicker, title: title),
        const SizedBox(height: 10),
        if (promotion != null)
          mapHomePromotionCard(
            promotion,
            onOpenPlace: onOpenPlace,
            onOpenCounty: onOpenCounty,
            onRoute: onRoute,
            onPlaceRoute: onPromotedPlaceRoute,
          )
        else
          mapHomeSuggestionCard(
            fallback!,
            whyLabel: mapHomeWhyLabel(fallback),
            onOpenCounty: onOpenCounty,
            onRoute: onRoute,
          ),
      ],
    );
  }
}

/// A heading and one chosen county card: the home county for a new user,
/// or the nearest unclaimed county as the next goal after a claim.
class MapHomeSuggestionTarget extends StatelessWidget {
  const MapHomeSuggestionTarget({
    super.key,
    required this.suggestion,
    required this.kicker,
    required this.title,
    this.isHome = false,
    this.onOpenCounty,
    this.onRoute,
    this.onStartTrip,
  });

  final MapHomeSuggestion suggestion;
  final String kicker;
  final String title;
  final bool isHome;
  final OpenCountyDetail? onOpenCounty;
  final OpenDirections? onRoute;

  /// Shown as the card's primary button when a Trip can be started.
  final VoidCallback? onStartTrip;

  @override
  Widget build(BuildContext context) {
    final start = onStartTrip;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MapHomeSectionHeading(kicker: kicker, title: title),
        const SizedBox(height: 10),
        mapHomeSuggestionCard(
          suggestion,
          whyLabel: mapHomeWhyLabel(suggestion, isHome: isHome),
          onOpenCounty: onOpenCounty,
          onRoute: onRoute,
        ),
        if (isHome && start != null) ...[
          const SizedBox(height: 10),
          MapHomePrimaryButton(label: 'Start a trip', onPressed: start),
        ],
      ],
    );
  }
}

/// "NEXT FOR YOU / Nearby and unclaimed": up to six counties, nearest
/// first, ending in "All N left". One card is shown across the sheet; an
/// empty row hides the section.
class MapHomeNearbyRow extends StatelessWidget {
  const MapHomeNearbyRow({
    super.key,
    required this.data,
    this.skip,
    this.onOpenCounty,
    this.onRoute,
    this.onSeeAllUnclaimed,
  });

  final MapHomeBoardData data;

  /// A county already shown above (the next goal), left out of the row.
  final int? skip;
  final OpenCountyDetail? onOpenCounty;
  final OpenDirections? onRoute;
  final OpenAllUnclaimed? onSeeAllUnclaimed;

  @override
  Widget build(BuildContext context) {
    final row = [
      for (final entry in data.unclaimedRow)
        if (entry.county.code != skip) entry,
    ];
    if (row.isEmpty) return const SizedBox.shrink();
    final seeAll = onSeeAllUnclaimed;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MapHomeSectionHeading(
          kicker: 'NEXT FOR YOU',
          title: 'Nearby and unclaimed',
          trailing: seeAll == null
              ? null
              : MapHomeSectionAction(
                  label: 'All ${data.unclaimedCount} left',
                  onTap: () => seeAll(context),
                ),
        ),
        const SizedBox(height: 10),
        if (row.length == 1)
          MapHomeUnclaimedCard(
            suggestion: row.first,
            fullWidth: true,
            onOpenCounty: onOpenCounty,
            onRoute: onRoute,
          )
        else
          SizedBox(
            height: MapHomeUnclaimedCard.height,
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
    );
  }
}

/// "GO DEEPER / Suggested places": with every county claimed, the
/// depth-rank and saved-place suggestions take over.
class MapHomeGoDeeperRow extends StatelessWidget {
  const MapHomeGoDeeperRow({
    super.key,
    required this.data,
    this.onOpenCounty,
    this.onRoute,
  });

  final MapHomeBoardData data;
  final OpenCountyDetail? onOpenCounty;
  final OpenDirections? onRoute;

  @override
  Widget build(BuildContext context) {
    final row = data.suggestions.take(MapHomeBoardData.maxUnclaimedCards);
    if (row.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const MapHomeSectionHeading(
          kicker: 'GO DEEPER',
          title: 'Suggested places',
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: MapHomeUnclaimedCard.height,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            itemCount: row.length,
            separatorBuilder: (context, index) => const SizedBox(width: 10),
            itemBuilder: (context, index) => MapHomeUnclaimedCard(
              suggestion: row.elementAt(index),
              pillLabel: 'Suggested',
              onOpenCounty: onOpenCounty,
              onRoute: onRoute,
            ),
          ),
        ),
      ],
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
        const MapHomeSectionHeading(
          kicker: 'PRIMARY TARGET',
          title: 'Your next best move',
        ),
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
