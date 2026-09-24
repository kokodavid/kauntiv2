import 'package:flutter/material.dart';

import '../../counties/county_paths.dart';
import '../../design/app_colors.dart';
import '../../widgets/app_county_shape.dart';
import '../design/app_type_scale.dart';

/// Opens driving directions in the maps app for a text destination;
/// resolves false when nothing could open it. Supplied by `app/`.
typedef AppOpenDirections = Future<bool> Function(String destination);

/// A card photo: the county or place photo (or the dashed county shape
/// when there's none) under a dark fade, with a title and a pinned
/// caption at the bottom and optional pills / actions in the corners.
class AppPhotoHeader extends StatelessWidget {
  const AppPhotoHeader({
    super.key,
    required this.county,
    required this.height,
    this.title,
    this.caption,
    this.imageUrl,
    this.topLeft,
    this.bottomRight,
    this.titleRightInset = 104,
  });

  final CountyPath county;
  /// Bottom-left title and pinned caption; left out when null.
  final String? title;
  final String? caption;
  final double height;
  final String? imageUrl;
  final Widget? topLeft;
  final Widget? bottomRight;

  /// Room kept for [bottomRight] so the title never runs under it.
  final double titleRightInset;

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
          if (title != null)
          Positioned(
            left: 12,
            right: bottomRight == null ? 12 : titleRightInset,
            bottom: 12,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title!,
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
                        caption ?? '',
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

/// A dark glass pill on a photo ("Unclaimed", "AD", "JUST UNLOCKED").
class AppPhotoPill extends StatelessWidget {
  const AppPhotoPill({super.key, required this.label});

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

/// A dark glass action pill for photo headers ("Route ›", "Save").
class AppPhotoButton extends StatelessWidget {
  const AppPhotoButton({
    super.key,
    required this.onPressed,
    this.label = 'Route',
    this.icon = Icons.chevron_right,
  });

  final VoidCallback onPressed;
  final String label;
  final IconData icon;

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
                label,
                style: AppTypeScale.action.copyWith(
                  fontSize: AppTypeScale.smallSize,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 2),
              Icon(icon, size: 16, color: Colors.white),
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
  AppOpenDirections open,
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
