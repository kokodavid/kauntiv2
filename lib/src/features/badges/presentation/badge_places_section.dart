import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/app_type_scale.dart';
import '../../../core/widgets/app_place_row.dart';
import '../../../core/widgets/app_place_sheet.dart';
import '../../discover/application/explore_providers.dart';
import '../application/badges_providers.dart';
import '../domain/county_badge_detail.dart';

/// "Places to start with" for a county not yet earned: the nearest few
/// places as the shared place rows (photo, summary, type, distance, save).
/// Waits for the user's position first so the list doesn't reorder once
/// distances arrive; without a position it lists them by name.
class BadgePlacesSection extends ConsumerWidget {
  const BadgePlacesSection({
    super.key,
    required this.countyCode,
    required this.places,
    this.onOpenPlace,
  });

  final int countyCode;
  final List<BadgeSuggestedPlace> places;
  final ValueChanged<String>? onOpenPlace;

  static String distanceLabel(double meters) => meters < 1000
      ? '${meters.round()} m'
      : '${(meters / 1000).toStringAsFixed(meters < 10000 ? 1 : 0)} km';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (places.isEmpty) return const SizedBox.shrink();
    final location = ref.watch(badgeUserLocationProvider);
    if (location.isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }
    final from = location.value;
    final saved = ref.watch(exploreSavedPlacesProvider);
    final open = onOpenPlace;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          from == null ? 'Places to start with' : 'Nearest places to start',
          style: AppTypeScale.itemTitle,
        ),
        for (final place in BadgeSuggestedPlace.nearest(places, from: from))
          AppPlaceRow(
            title: place.name,
            description: place.summary ?? '',
            categoryLabel: AppPlaceSheet.typeLabel(place.type),
            thumbnailUrl: place.thumbnailUrl,
            distanceLabel: switch (from) {
              null => null,
              final at => switch (place.metersFrom(at.latitude, at.longitude)) {
                null => null,
                final meters => distanceLabel(meters),
              },
            },
            saved: saved[place.id] ?? place.saved,
            onTap: open == null ? null : () => open(place.id),
            onSaveChanged: (value) => ref
                .read(exploreSavedPlacesProvider.notifier)
                .setSaved(
                  countyCode: countyCode,
                  placeId: place.id,
                  saved: value,
                ),
          ),
      ],
    );
  }
}
