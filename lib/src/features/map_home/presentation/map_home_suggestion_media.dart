import 'package:flutter/material.dart';

import '../../../core/design/app_type_scale.dart';
import '../../../counties/county_paths.dart';
import '../../../design/app_colors.dart';
import '../../../widgets/app_county_shape.dart';
import '../domain/map_home_models.dart';
import 'map_home_links.dart';

class MapHomeSuggestionPhotoHeader extends StatelessWidget {
  const MapHomeSuggestionPhotoHeader({
    super.key,
    required this.suggestion,
    required this.height,
    this.showReasonPill = true,
    this.trailing,
  });

  final MapHomeSuggestion suggestion;
  final double height;
  final bool showReasonPill;

  /// Bottom-right action on the photo (the featured card's Route button).
  final Widget? trailing;

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
          if (showReasonPill)
            Positioned(
              top: 10,
              right: 10,
              child: _ReasonPill(
                label: _shortReasonLabels[suggestion.reason]!,
              ),
            ),
          Positioned(
            left: 12,
            right: trailing == null ? 72 : 100,
            bottom: 12,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  suggestion.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypeScale.photoTitle,
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
                        style: AppTypeScale.photoCaption,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (trailing case final action?)
            Positioned(right: 12, bottom: 12, child: action),
        ],
      ),
    );
  }
}

/// A dark glass "Route ›" pill for photo headers.
class MapHomeRouteButton extends StatelessWidget {
  const MapHomeRouteButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.42),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 6, 6, 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Route',
                style: AppTypeScale.action.copyWith(
                  fontSize: AppTypeScale.smallSize,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 2),
              const Icon(Icons.chevron_right, size: 16, color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}

/// Opens directions for [suggestion] via [open], with a note when no
/// maps app could take it.
Future<void> openSuggestionRoute(
  BuildContext context,
  MapHomeSuggestion suggestion,
  OpenDirections open,
) async {
  final messenger = ScaffoldMessenger.of(context);
  bool opened;
  try {
    opened = await open(suggestion.directionsQuery);
  } on Object {
    opened = false;
  }
  if (!opened) {
    messenger.showSnackBar(
      const SnackBar(content: Text("Couldn't open directions.")),
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
        style: AppTypeScale.photoCaption.copyWith(color: Colors.white),
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
