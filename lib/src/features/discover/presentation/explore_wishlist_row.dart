import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../design/app_colors.dart';
import '../application/explore_providers.dart';
import '../domain/explore_board.dart';
import 'explore_place_row.dart';
import 'explore_styles.dart';

/// A SAVED row (v1 `_WishlistPlaceRow`): a tick box, then thumbnail,
/// title and summary. The tick is the row's one state control, so there's
/// no bookmark icon here; tapping the rest opens Place Detail.
class ExploreWishlistRow extends ConsumerWidget {
  const ExploreWishlistRow({super.key, required this.place, this.onOpen});

  final ExplorePlace place;
  final OpenExplorePlace? onOpen;

  Future<void> _toggle(BuildContext context, WidgetRef ref, bool seen) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref
          .read(exploreTickedPlacesProvider.notifier)
          .setTicked(placeId: place.id, ticked: !seen);
    } on Object {
      messenger.showSnackBar(
        const SnackBar(content: Text("Couldn't update that tick.")),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final seen =
        ref.watch(exploreTickedPlacesProvider.select((m) => m[place.id])) ??
        place.seen;
    final open = onOpen;
    final thumbnail = place.thumbnailUrl;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            checked: seen,
            label: 'Visited ${place.title}',
            child: InkResponse(
              onTap: () => _toggle(context, ref, seen),
              radius: 18,
              child: Container(
                width: 17,
                height: 17,
                margin: const EdgeInsets.only(top: 2),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(
                    color: seen ? AppColors.green : AppColors.lockedStroke,
                    width: 1.8,
                  ),
                  color: seen ? AppColors.green : Colors.transparent,
                ),
                child: seen
                    ? const Icon(Icons.check, size: 13, color: Colors.white)
                    : null,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: InkWell(
              onTap: open == null ? null : () => open(context, place.id),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: SizedBox.square(
                      dimension: 40,
                      child: thumbnail == null
                          ? const ColoredBox(color: AppColors.lockedFill)
                          : Image.network(
                              thumbnail,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  const ColoredBox(color: AppColors.lockedFill),
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
                          style: ExploreStyles.wishlistTitle(seen: seen),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          place.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: ExploreStyles.placeBody,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (seen) ...[
            const SizedBox(width: 8),
            const Text('COMPLETE', style: ExploreStyles.completeLabel),
          ],
        ],
      ),
    );
  }
}
