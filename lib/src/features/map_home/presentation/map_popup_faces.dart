import 'package:flutter/material.dart';

import '../../../core/design/app_type_scale.dart';
import '../../../core/domain/map_place.dart';
import '../../../core/domain/place_type.dart';
import '../../../core/widgets/app_photo_parts.dart';
import '../../../counties/county_paths.dart';
import '../../../design/app_colors.dart';
import 'map_popup_shape.dart';

/// The two faces of a place popup. The front is the photo with the name and
/// county; the back is the details, with the way into the place.
class MapPopupFront extends StatelessWidget {
  const MapPopupFront({
    super.key,
    required this.place,
    required this.onDetails,
    required this.onClose,
  });

  final MapPlace place;
  final VoidCallback onDetails;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final county = CountyPaths.byCode[place.countyCode];
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 6, 6, 6 + MapPopupShape.tailHeight),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(21),
        child: LayoutBuilder(
          builder: (context, box) => Stack(
            children: [
              if (county != null)
                AppPhotoHeader(
                  county: county,
                  title: place.name,
                  caption: '${county.name} County',
                  imageUrl: place.thumbnailUrl,
                  height: box.maxHeight,
                  topLeft: AppPhotoPill(label: PlaceType.of(place.type).label),
                  bottomRight: AppPhotoButton(
                    label: 'Details',
                    onPressed: onDetails,
                  ),
                )
              else
                ColoredBox(
                  color: AppColors.foreground,
                  child: SizedBox.expand(
                    child: Center(
                      child: Text(place.name, style: AppTypeScale.photoTitle),
                    ),
                  ),
                ),
              Positioned(top: 8, right: 8, child: PopupCloseButton(onClose)),
            ],
          ),
        ),
      ),
    );
  }
}

class MapPopupBack extends StatelessWidget {
  const MapPopupBack({
    super.key,
    required this.place,
    required this.onClose,
    this.onOpen,
    this.onRoute,
  });

  final MapPlace place;
  final VoidCallback onClose;
  final VoidCallback? onOpen;
  final VoidCallback? onRoute;

  @override
  Widget build(BuildContext context) {
    final county = CountyPaths.byCode[place.countyCode];
    final summary = place.summary?.trim();
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        18,
        16,
        14,
        16 + MapPopupShape.tailHeight,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    place.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: AppTypeScale.family,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      height: 1.25,
                      color: AppColors.foreground,
                    ),
                  ),
                ),
              ),
              PopupCloseButton(onClose, dark: true),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(
                Icons.place_outlined,
                size: 14,
                color: AppColors.mutedForeground,
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  [
                    PlaceType.of(place.type).label,
                    if (county != null) '${county.name} County',
                  ].join(' · '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: AppTypeScale.family,
                    fontSize: AppTypeScale.smallSize,
                    color: AppColors.mutedForeground,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Text(
              summary == null || summary.isEmpty
                  ? 'No description yet.'
                  : summary,
              overflow: TextOverflow.fade,
              style: const TextStyle(
                fontFamily: AppTypeScale.family,
                fontSize: AppTypeScale.bodySize,
                height: 1.45,
                color: AppColors.foreground,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Row(
              children: [
                if (onOpen != null)
                  Expanded(
                    child: _Action(
                      label: 'View place',
                      filled: true,
                      onTap: onOpen!,
                    ),
                  ),
                if (onOpen != null && onRoute != null) const SizedBox(width: 8),
                if (onRoute != null)
                  Expanded(
                    child: _Action(
                      label: 'Route',
                      filled: onOpen == null,
                      onTap: onRoute!,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Action extends StatelessWidget {
  const _Action({
    required this.label,
    required this.filled,
    required this.onTap,
  });

  final String label;
  final bool filled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: filled ? AppColors.accent : Colors.white,
      shape: StadiumBorder(
        side: filled
            ? BorderSide.none
            : const BorderSide(color: AppColors.cardBorder, width: 1.5),
      ),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: SizedBox(
          height: 42,
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontFamily: AppTypeScale.family,
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: filled ? Colors.white : AppColors.foreground,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A small round close button: dark glass on a photo, light on the back.
class PopupCloseButton extends StatelessWidget {
  const PopupCloseButton(this.onTap, {super.key, this.dark = false});

  final VoidCallback onTap;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Close',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: dark
                ? const Color(0xFFF4F4F5)
                : Colors.black.withValues(alpha: 0.42),
          ),
          child: Icon(
            Icons.close_rounded,
            size: 17,
            color: dark ? AppColors.foreground : Colors.white,
          ),
        ),
      ),
    );
  }
}
