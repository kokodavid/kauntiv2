import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/app_place_row.dart';
import '../../../design/app_colors.dart';
import '../application/explore_providers.dart';
import '../domain/explore_board.dart';
import 'explore_styles.dart';

typedef OpenExploreCounty = void Function(BuildContext context, int countyCode);
typedef OpenExplorePlace = void Function(BuildContext context, String placeId);

/// Up to a few [ExplorePlaceRow]s with dividers, or a "no places" note.
class ExplorePlaceList extends StatelessWidget {
  const ExplorePlaceList({
    super.key,
    required this.places,
    required this.countyCode,
    this.onOpenPlace,
  });

  final List<ExplorePlace> places;
  final int countyCode;
  final OpenExplorePlace? onOpenPlace;

  @override
  Widget build(BuildContext context) {
    if (places.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Text(
          'No places on file yet for this county.',
          style: ExploreStyles.emptyBody,
        ),
      );
    }
    return Column(
      children: [
        for (var i = 0; i < places.length; i++) ...[
          ExplorePlaceRow(
            place: places[i],
            countyCode: countyCode,
            onOpen: onOpenPlace,
          ),
          if (i != places.length - 1)
            const Divider(height: 1, color: AppColors.exploreBorder),
        ],
      ],
    );
  }
}

/// A place row inside Explore's county cards: the shared [AppPlaceRow]
/// with Explore's saved-place state. Tapping opens Place Detail when
/// [onOpen] is set.
class ExplorePlaceRow extends ConsumerWidget {
  const ExplorePlaceRow({
    super.key,
    required this.place,
    required this.countyCode,
    this.onOpen,
  });

  final ExplorePlace place;
  final int countyCode;
  final OpenExplorePlace? onOpen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final savedOverride = ref.watch(
      exploreSavedPlacesProvider.select((saved) => saved[place.id]),
    );
    final open = onOpen;
    return AppPlaceRow(
      title: place.title,
      description: place.description,
      categoryLabel: place.category.label,
      thumbnailUrl: place.thumbnailUrl,
      promotionLabel: place.isPromoted ? place.promotionLabel : null,
      distanceLabel: place.distanceLabel,
      saved: savedOverride ?? place.saved,
      onTap: open == null ? null : () => open(context, place.id),
      onSaveChanged: (saved) => ref
          .read(exploreSavedPlacesProvider.notifier)
          .setSaved(countyCode: countyCode, placeId: place.id, saved: saved),
    );
  }
}
