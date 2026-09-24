import 'package:flutter/material.dart';

import '../../../counties/county_paths.dart';
import '../../../design/app_colors.dart';
import '../../../design/app_text_styles.dart';
import '../../../widgets/app_county_shape.dart';
import '../domain/map_home_models.dart';
import 'map_home_links.dart';

class MapHomeSuggestionPhotoHeader extends StatelessWidget {
  const MapHomeSuggestionPhotoHeader({
    super.key,
    required this.suggestion,
    required this.height,
  });

  final MapHomeSuggestion suggestion;
  final double height;

  @override
  Widget build(BuildContext context) {
    final imageUrl = suggestion.highlightImageUrl;

    return SizedBox(
      height: height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (imageUrl == null)
            _NoPhotoFill(county: suggestion.county)
          else
            Image.network(
              imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  _NoPhotoFill(county: suggestion.county),
            ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [Color(0x99000000), Color(0x08000000)],
                stops: [0.0, 0.65],
              ),
            ),
          ),
          Positioned(
            top: 10,
            right: 10,
            child: _ReasonPill(label: _shortReasonLabels[suggestion.reason]!),
          ),
          Positioned(
            left: 12,
            right: 72,
            bottom: 12,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  suggestion.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.heroHeading.copyWith(fontSize: 18),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    const Icon(
                      Icons.place_outlined,
                      size: 14,
                      color: AppColors.heroSubheadingText,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        suggestion.placeName == null
                            ? suggestion.distanceAway
                            : '${suggestion.county.name} County',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.heroSubheadingText,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class MapHomeSuggestionStatsRow extends StatelessWidget {
  const MapHomeSuggestionStatsRow({super.key, required this.stats});

  final List<String> stats;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < stats.length; i++) ...[
          if (i > 0) const SizedBox(width: 12),
          Text(stats[i], style: AppTextStyles.bodySmall),
        ],
      ],
    );
  }
}

class MapHomeSuggestionCountySwatch extends StatelessWidget {
  const MapHomeSuggestionCountySwatch({super.key, required this.county});

  final CountyPath county;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 64,
      height: 64,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppColors.cardBorder),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Center(
          child: SizedBox(
            width: 44,
            height: 44,
            child: AppCountyShape(county: county, fill: AppColors.accent),
          ),
        ),
      ),
    );
  }
}

class MapHomeSuggestionTapTarget extends StatelessWidget {
  const MapHomeSuggestionTapTarget({
    super.key,
    required this.suggestion,
    required this.child,
    this.onOpenCounty,
  });

  final MapHomeSuggestion suggestion;
  final Widget child;
  final OpenCountyDetail? onOpenCounty;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        final open = onOpenCounty;
        if (open != null) return open(context, suggestion.county.code);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${suggestion.county.name} details are next.'),
          ),
        );
      },
      child: child,
    );
  }
}

class _ReasonPill extends StatelessWidget {
  const _ReasonPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.42),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: AppTextStyles.bodySmall.copyWith(color: Colors.white),
      ),
    );
  }
}

class _NoPhotoFill extends StatelessWidget {
  const _NoPhotoFill({required this.county});

  final CountyPath county;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.lockedFill,
      child: Center(
        child: SizedBox(
          width: 72,
          height: 72,
          child: AppCountyShape(
            county: county,
            fill: Colors.transparent,
            stroke: AppColors.lockedStroke,
            strokeWidth: 2,
            dashed: true,
          ),
        ),
      ),
    );
  }
}

const _shortReasonLabels = {
  MapHomeSuggestionReason.depthRank: 'Depth rank',
  MapHomeSuggestionReason.savedHere: 'Saved here',
  MapHomeSuggestionReason.unclaimed: 'Unclaimed',
};
