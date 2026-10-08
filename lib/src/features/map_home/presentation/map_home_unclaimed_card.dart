import 'package:flutter/material.dart';

import '../../../core/design/app_type_scale.dart';
import '../../../core/widgets/app_photo_parts.dart';
import '../../../design/app_colors.dart';
import '../domain/map_home_models.dart';
import 'map_home_links.dart';
import 'map_home_suggestion_media.dart';

/// One "Nearby and unclaimed" card: the county photo with its name,
/// distance and an "Unclaimed" pill, then a Route row. Tapping the photo
/// opens County Detail.
class MapHomeUnclaimedCard extends StatelessWidget {
  const MapHomeUnclaimedCard({
    super.key,
    required this.suggestion,
    this.onOpenCounty,
    this.onRoute,
    this.pillLabel = 'Unclaimed',
    this.fullWidth = false,
  });

  final MapHomeSuggestion suggestion;

  /// The photo pill: "Unclaimed", or "Suggested" in Go deeper.
  final String pillLabel;

  /// A row with a single card shows it across the sheet.
  final bool fullWidth;
  final OpenCountyDetail? onOpenCounty;
  final OpenDirections? onRoute;

  static const width = 184.0;
  static const height = 240.0;
  static const photoHeight = 184.0;

  @override
  Widget build(BuildContext context) {
    final route = onRoute;
    return Container(
      width: fullWidth ? double.infinity : width,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.cardBorder),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: () =>
                openCountyOrNote(context, suggestion.county, onOpenCounty),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: AppPhotoHeader(
                county: suggestion.county,
                title: suggestion.county.name,
                caption: suggestion.distanceAway,
                imageUrl: suggestion.highlightImageUrl,
                height: photoHeight,
                // Narrow row cards give the whole width to the name; the section
                // heading already says they are unclaimed.
                bottomRight: fullWidth ? AppPhotoPill(label: pillLabel) : null,
              ),
            ),
          ),
          if (route != null)
            InkWell(
              onTap: () =>
                  openRoute(context, suggestion.directionsQuery, route),
              borderRadius: BorderRadius.circular(12),
              child: const Padding(
                padding: EdgeInsets.fromLTRB(8, 8, 4, 6),
                child: Row(
                  children: [
                    Text('Route', style: AppTypeScale.action),
                    Spacer(),
                    Icon(
                      Icons.chevron_right,
                      size: 18,
                      color: AppColors.accent,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
