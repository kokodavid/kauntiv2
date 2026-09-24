import 'package:flutter/material.dart';

import '../../../core/design/app_type_scale.dart';
import '../../../counties/county_paths.dart';
import '../../../design/app_colors.dart';
import '../../../widgets/app_county_shape.dart';
import '../domain/map_home_models.dart';
import '../domain/map_home_promotion.dart';
import 'map_home_links.dart';
import 'map_home_suggestion_media.dart';

/// For You's top card ("Your next best move"): an inset photo with a
/// title and a Route button; below it the county, one line of context,
/// stats and the county shape. Shows the active promoted place (with its
/// AD label) or, when nothing is promoted, the best suggestion.
class MapHomeFeatureCard extends StatelessWidget {
  const MapHomeFeatureCard({
    super.key,
    required this.county,
    required this.photoTitle,
    required this.photoCaption,
    required this.line,
    required this.stats,
    required this.destination,
    required this.onTap,
    this.photoUrl,
    this.disclosureLabel,
    this.onRoute,
  });

  /// The promoted place: opens Place Detail when that link is wired.
  factory MapHomeFeatureCard.promotion(
    MapHomePromotedPlace promotion, {
    OpenPlaceDetail? onOpenPlace,
    OpenCountyDetail? onOpenCounty,
    OpenDirections? onRoute,
  }) => MapHomeFeatureCard(
    county: promotion.county,
    photoTitle: promotion.placeName,
    photoCaption: '${promotion.county.name} County',
    photoUrl: promotion.photoUrl,
    disclosureLabel: promotion.disclosureLabel,
    line: promotion.summary ?? 'Sponsored by ${promotion.sponsorName}',
    stats: promotion.stats,
    destination: promotion.directionsQuery,
    onRoute: onRoute,
    onTap: (context) => onOpenPlace != null
        ? onOpenPlace(context, promotion.placeId)
        : openCountyOrNote(context, promotion.county, onOpenCounty),
  );

  /// A For You suggestion: opens County Detail.
  factory MapHomeFeatureCard.suggestion(
    MapHomeSuggestion suggestion, {
    OpenCountyDetail? onOpenCounty,
    OpenDirections? onRoute,
  }) => MapHomeFeatureCard(
    county: suggestion.county,
    photoTitle: suggestion.title,
    photoCaption: suggestion.placeName == null
        ? suggestion.distanceAway
        : '${suggestion.county.name} County',
    photoUrl: suggestion.highlightImageUrl,
    line: '${suggestion.reasonLabel} · ${suggestion.distanceAway}',
    stats: suggestion.stats,
    destination: suggestion.directionsQuery,
    onRoute: onRoute,
    onTap: (context) =>
        openCountyOrNote(context, suggestion.county, onOpenCounty),
  );

  final CountyPath county;
  final String photoTitle;
  final String photoCaption;
  final String? photoUrl;

  /// Set for paid placements ("AD"); shown on the photo.
  final String? disclosureLabel;
  final String line;
  final List<({String value, String label})> stats;
  final String destination;
  final void Function(BuildContext context) onTap;
  final OpenDirections? onRoute;

  @override
  Widget build(BuildContext context) {
    final route = onRoute;
    final label = disclosureLabel;

    return GestureDetector(
      onTap: () => onTap(context),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppColors.cardBorder),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: MapHomePhotoHeader(
                county: county,
                title: photoTitle,
                caption: photoCaption,
                imageUrl: photoUrl,
                height: 136,
                topLeft: label == null ? null : MapHomePhotoPill(label: label),
                bottomRight: route == null
                    ? null
                    : MapHomeRouteButton(
                        onPressed: () => openRoute(context, destination, route),
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 6, 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _Details(card: this)),
                  const SizedBox(width: 12),
                  _CountyTile(county: county),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Details extends StatelessWidget {
  const _Details({required this.card});

  final MapHomeFeatureCard card;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '${card.county.name} County',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTypeScale.compactTitle,
        ),
        const SizedBox(height: 2),
        Text(
          card.line,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: AppTypeScale.small,
        ),
        if (card.stats.isNotEmpty) ...[
          const SizedBox(height: 8),
          const Divider(height: 1, color: AppColors.trackInactive),
          const SizedBox(height: 8),
          Row(
            children: [
              for (final (i, stat) in card.stats.indexed) ...[
                if (i > 0) const SizedBox(width: 16),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        stat.value,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypeScale.compactStatValue,
                      ),
                      Text(stat.label, style: AppTypeScale.compactStatLabel),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ],
      ],
    );
  }
}

/// The county's shape in a white squircle (County Detail's treatment).
class _CountyTile extends StatelessWidget {
  const _CountyTile({required this.county});

  final CountyPath county;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      height: 72,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.countyShapeCardBorder),
        borderRadius: BorderRadius.circular(18),
      ),
      child: AppCountyShape(county: county, fill: AppColors.accent),
    );
  }
}
