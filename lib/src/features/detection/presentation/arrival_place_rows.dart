import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/app_type_scale.dart';
import '../../../design/app_colors.dart';
import '../../discover/application/explore_providers.dart';
import '../../discover/domain/county_detail.dart';

/// The arrival sheet's place list (v1 used the shared place row): saved
/// places first, at most [maxShown]. Saving goes through Explore's saved
/// places, so Explore and County Detail agree.
class ArrivalPlaceRows extends StatelessWidget {
  const ArrivalPlaceRows({
    super.key,
    required this.data,
    this.onOpenPlace,
    this.maxShown = 4,
  });

  final CountyDetailData data;
  final void Function(String placeId)? onOpenPlace;

  /// v1's design showed four.
  final int maxShown;

  @override
  Widget build(BuildContext context) {
    // Stable sort: saved first, otherwise the county's own order.
    final ordered = [
      ...data.places.where((p) => p.saved),
      ...data.places.where((p) => !p.saved),
    ].take(maxShown).toList();
    return Column(
      children: [
        for (var i = 0; i < ordered.length; i++) ...[
          if (i != 0) const Divider(height: 1, color: AppColors.exploreBorder),
          _ArrivalPlaceRow(
            place: ordered[i],
            countyCode: data.county.code,
            onOpen: onOpenPlace,
          ),
        ],
      ],
    );
  }
}

class _ArrivalPlaceRow extends ConsumerWidget {
  const _ArrivalPlaceRow({
    required this.place,
    required this.countyCode,
    this.onOpen,
  });

  final CountyDetailPlace place;
  final int countyCode;
  final void Function(String placeId)? onOpen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final saved =
        ref.watch(
          exploreSavedPlacesProvider.select((saved) => saved[place.id]),
        ) ??
        place.saved;
    final thumbnail = place.thumbnailUrl;
    final open = onOpen;
    return InkWell(
      onTap: open == null ? null : () => open(place.id),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox.square(
                dimension: 44,
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
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    place.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypeScale.itemTitle,
                  ),
                  Text(
                    '${place.category.label} · ${place.description}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypeScale.small,
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: saved ? 'Remove from saved' : 'Save',
              onPressed: () => _setSaved(context, ref, !saved),
              icon: Icon(
                saved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                size: 20,
                color: saved ? AppColors.green : AppColors.mutedForeground,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _setSaved(BuildContext context, WidgetRef ref, bool saved) async {
    try {
      await ref
          .read(exploreSavedPlacesProvider.notifier)
          .setSaved(countyCode: countyCode, placeId: place.id, saved: saved);
    } on Object {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Couldn't update saved places.")),
      );
    }
  }
}
