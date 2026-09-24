import 'package:flutter/material.dart';

import '../../../core/design/app_type_scale.dart';
import '../../../counties/county_paths.dart';
import '../../../design/app_colors.dart';
import '../../../widgets/app_county_shape.dart';
import 'map_home_links.dart';

/// A For You photo: the county or place photo (or the dashed county shape
/// when there's none) under a dark fade, with a title and a pinned
/// caption at the bottom and optional pills / actions in the corners.
class MapHomePhotoHeader extends StatelessWidget {
  const MapHomePhotoHeader({
    super.key,
    required this.county,
    required this.title,
    required this.caption,
    required this.height,
    this.imageUrl,
    this.topLeft,
    this.bottomRight,
  });

  final CountyPath county;
  final String title;
  final String caption;
  final double height;
  final String? imageUrl;
  final Widget? topLeft;
  final Widget? bottomRight;

  @override
  Widget build(BuildContext context) {
    final url = imageUrl;
    return SizedBox(
      height: height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (url == null)
            _NoPhotoFill(county: county)
          else
            Image.network(
              url,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  _NoPhotoFill(county: county),
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
          if (topLeft case final pill?)
            Positioned(top: 10, left: 10, child: pill),
          Positioned(
            left: 12,
            right: bottomRight == null ? 12 : 104,
            bottom: 12,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypeScale.photoTitle,
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    const Icon(
                      Icons.place_outlined,
                      size: 13,
                      color: AppColors.heroSubheadingText,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        caption,
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
          if (bottomRight case final action?)
            Positioned(right: 10, bottom: 10, child: action),
        ],
      ),
    );
  }
}

/// A dark glass pill on a photo ("Unclaimed", "AD").
class MapHomePhotoPill extends StatelessWidget {
  const MapHomePhotoPill({super.key, required this.label});

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

/// Opens directions to [destination] via [open], with a note when no maps
/// app could take it.
Future<void> openRoute(
  BuildContext context,
  String destination,
  OpenDirections open,
) async {
  final messenger = ScaffoldMessenger.of(context);
  bool opened;
  try {
    opened = await open(destination);
  } on Object {
    opened = false;
  }
  if (!opened) {
    messenger.showSnackBar(
      const SnackBar(content: Text("Couldn't open directions.")),
    );
  }
}

/// Opens County Detail, or says it's coming when the link isn't wired.
void openCountyOrNote(
  BuildContext context,
  CountyPath county,
  OpenCountyDetail? open,
) {
  if (open != null) return open(context, county.code);
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('${county.name} details are next.')),
  );
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
