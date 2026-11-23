import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/app_type_scale.dart';
import '../../../core/services/connectivity_provider.dart';
import '../../../design/app_colors.dart';
import '../application/place_photos_providers.dart';
import '../domain/photo_submission.dart';
import '../domain/place_photo_item.dart';
import 'place_photo_add_flow.dart';
import 'place_photo_chip.dart';
import 'place_photo_tile.dart';
import 'place_photo_viewer.dart';
import 'place_photos_add_nudge_banner.dart';
import 'place_photos_gallery_screen.dart';

/// Place Detail's Photos section, now above About: a heading with the
/// count, a strip of photos only, "See all" (only once there are more
/// photos than the strip can show without scrolling), and one quiet
/// chip about the user's own waiting or reviewed photos. Add photo no
/// longer shows inline here -- it's reachable from "See all"
/// (`PlacePhotosGalleryScreen`) when that's showing, and always from
/// the floating action bar.
class PlacePhotosSection extends ConsumerWidget {
  const PlacePhotosSection({
    super.key,
    required this.placeId,
    required this.placeName,
    required this.photos,
    required this.canAdd,
    required this.onOpenMyPhotos,
    this.onChooseUsername,
  });

  final String placeId;
  final String placeName;
  final List<PlacePhotoItem> photos;

  /// Whether this place takes photos (reviewed and not archived).
  final bool canAdd;
  final VoidCallback onOpenMyPhotos;
  final VoidCallback? onChooseUsername;

  static const _maxInStrip = 8;

  /// Experiment: with exactly one photo, skip the strip row entirely
  /// (the count still shows in the heading). Flip back to `false` to
  /// revert to always showing the strip.
  static const _hideStripForSinglePhoto = true;

  /// Matches [PlacePhotoTile]'s default square size and the strip's
  /// separator width, so the "how many fit without scrolling" count
  /// below is exact, not a guess.
  static const _tileWidth = 120.0;
  static const _tileGap = 8.0;

  void _add(BuildContext context, WidgetRef ref) => startAddPhoto(
    context,
    ref,
    placeId: placeId,
    onChooseUsername: onChooseUsername,
  );

  /// How many tiles fit in [maxWidth] with no horizontal scrolling --
  /// below this count the strip already shows everything, so "See
  /// all" would have nothing more to reveal.
  static int _fitCount(double maxWidth) =>
      ((maxWidth + _tileGap) / (_tileWidth + _tileGap)).floor();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enabled = ref.watch(placePhotosEnabledProvider).value == true;
    final showAdd = canAdd && enabled;
    final offline = ref.watch(connectivityProvider).isOffline;
    final List<PhotoSubmission> mine = showAdd
        ? ref.watch(myPlacePhotosProvider(placeId)).value ?? const []
        : const [];
    final shown = photos.take(_maxInStrip).toList();
    final hideForSingle = photos.length == 1 && _hideStripForSinglePhoto;
    return LayoutBuilder(
      builder: (context, constraints) {
        final showSeeAll = photos.length > _fitCount(constraints.maxWidth);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!hideForSingle) ...[
              SizedBox(
                height: 32,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'Gallery',
                      style: AppTypeScale.sectionTitle.copyWith(
                        fontSize: AppTypeScale.cardTitleSize,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${photos.length}',
                      style: const TextStyle(
                        fontFamily: AppTypeScale.family,
                        fontSize: 12,
                        color: AppColors.mutedForeground,
                      ),
                    ),
                    const Spacer(),
                    if (showSeeAll)
                      TextButton(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => PlacePhotosGalleryScreen(
                              placeName: placeName,
                              photos: photos,
                              offline: offline,
                              onAdd: showAdd ? () => _add(context, ref) : null,
                            ),
                          ),
                        ),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.accent,
                        ),
                        child: const Text('See all'),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
            if (photos.isNotEmpty && showAdd)
              PlacePhotosAddNudgeBanner(onAdd: () => _add(context, ref)),
            if (photos.isEmpty)
              Text(
                showAdd
                    ? 'Be the first to add a photo.'
                    : 'No photos of this place yet.',
                style: const TextStyle(
                  fontFamily: AppTypeScale.family,
                  fontSize: 13,
                  color: AppColors.mutedForeground,
                ),
              )
            else if (hideForSingle)
              const SizedBox.shrink()
            else
              SizedBox(
                height: 120,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  clipBehavior: Clip.none,
                  itemCount: shown.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, index) => PlacePhotoTile(
                    photo: shown[index],
                    onTap: () => openPlacePhotos(context, photos, index),
                  ),
                ),
              ),
            if (mine.isNotEmpty) ...[
              const SizedBox(height: 12),
              PlacePhotoChip(submissions: mine, onOpen: onOpenMyPhotos),
            ],
          ],
        );
      },
    );
  }
}
