import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/app_type_scale.dart';
import '../../../core/services/connectivity_provider.dart';
import '../../../design/app_colors.dart';
import '../application/place_photos_providers.dart';
import '../domain/photo_submission.dart';
import '../domain/place_photo_item.dart';
import 'place_photo_add_flow.dart';
import 'place_photo_add_tile.dart';
import 'place_photo_chip.dart';
import 'place_photo_tile.dart';
import 'place_photo_viewer.dart';
import 'place_photos_gallery_screen.dart';

/// Place Detail's Photos section: a heading with the count, a strip with
/// the Add photo tile first, "See all", and one quiet chip about the user's
/// own waiting or reviewed photos. Without the add tile (feature paused,
/// place not open for photos) the published photos still show.
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

  void _add(BuildContext context, WidgetRef ref) => startAddPhoto(
    context,
    ref,
    placeId: placeId,
    onChooseUsername: onChooseUsername,
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enabled = ref.watch(placePhotosEnabledProvider).value == true;
    final showAdd = canAdd && enabled;
    final offline = ref.watch(connectivityProvider).isOffline;
    final List<PhotoSubmission> mine = showAdd
        ? ref.watch(myPlacePhotosProvider(placeId)).value ?? const []
        : const [];
    final shown = photos.take(_maxInStrip).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 32,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text('Photos', style: AppTypeScale.sectionTitle),
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
              if (photos.length > 2 || (photos.isNotEmpty && showAdd))
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
        if (photos.isEmpty && showAdd)
          PlacePhotoEmptyInvite(
            offline: offline,
            onPressed: () => _add(context, ref),
          )
        else if (photos.isEmpty)
          const Text(
            'No photos of this place yet.',
            style: TextStyle(
              fontFamily: AppTypeScale.family,
              fontSize: 13,
              color: AppColors.mutedForeground,
            ),
          )
        else
          SizedBox(
            height: 120,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              itemCount: shown.length + (showAdd ? 1 : 0),
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                if (showAdd && index == 0) {
                  return PlacePhotoAddTile(
                    offline: offline,
                    onPressed: () => _add(context, ref),
                  );
                }
                final at = index - (showAdd ? 1 : 0);
                return PlacePhotoTile(
                  photo: shown[at],
                  onTap: () => openPlacePhotos(context, photos, at),
                );
              },
            ),
          ),
        if (mine.isNotEmpty) ...[
          const SizedBox(height: 12),
          PlacePhotoChip(submissions: mine, onOpen: onOpenMyPhotos),
        ],
      ],
    );
  }
}
