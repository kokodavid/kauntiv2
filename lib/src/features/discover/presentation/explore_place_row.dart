import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../design/app_colors.dart';
import '../application/explore_providers.dart';
import '../domain/explore_board.dart';
import 'explore_save_icon.dart';
import 'explore_styles.dart';

/// The 54px-thumbnail place row inside Explore's county cards (v1
/// `DiscoverPlaceRow`). Tapping opens Place Detail when [onOpen] is set.
class ExplorePlaceRow extends ConsumerWidget {
  const ExplorePlaceRow({
    super.key,
    required this.place,
    required this.countyCode,
    this.onOpen,
  });

  final ExplorePlace place;
  final int countyCode;
  final void Function(BuildContext context, String placeId)? onOpen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final savedOverride = ref.watch(
      exploreSavedPlacesProvider.select((saved) => saved[place.id]),
    );
    final thumbnail = place.thumbnailUrl;
    final open = onOpen;

    return InkWell(
      onTap: open == null ? null : () => open(context, place.id),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox.square(
                dimension: 54,
                child: thumbnail == null
                    ? const ColoredBox(color: AppColors.explorePhotoPlaceholder)
                    : Image.network(
                        thumbnail,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const ColoredBox(
                              color: AppColors.explorePhotoPlaceholder,
                            ),
                      ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(child: _PlaceText(place: place)),
            ExploreSaveIcon(
              saved: savedOverride ?? place.saved,
              onChanged: (saved) => ref
                  .read(exploreSavedPlacesProvider.notifier)
                  .setSaved(
                    countyCode: countyCode,
                    placeId: place.id,
                    saved: saved,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlaceText extends StatelessWidget {
  const _PlaceText({required this.place});

  final ExplorePlace place;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          place.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: ExploreStyles.placeTitle,
        ),
        Text(
          place.description,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: ExploreStyles.placeBody,
        ),
        const SizedBox(height: 3),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.exploreCategoryFill,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                place.category.label.toUpperCase(),
                style: ExploreStyles.categoryChip,
              ),
            ),
            if (place.distanceLabel case final distance?) ...[
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  '· $distance',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: ExploreStyles.placeDistance,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}
