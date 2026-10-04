import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/app_type_scale.dart';
import '../../../design/app_colors.dart';
import '../application/public_trip_viewer_providers.dart';
import 'public_trip_card.dart';

/// Home's "Trips from other explorers" row: public trips near the viewer's
/// home county, most unexplored counties first. Shows nothing at all while
/// loading, when public trips are off, or when there are none, so Home never
/// gains a blank gap or an error for an optional extra.
class PublicTripsHomeRow extends ConsumerWidget {
  const PublicTripsHomeRow({
    super.key,
    required this.countyCode,
    required this.onOpenTrip,
  });

  /// The viewer's home county; null hides the row.
  final int? countyCode;
  final void Function(String publicationId) onOpenTrip;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final code = countyCode;
    if (code == null) return const SizedBox.shrink();
    final trips = ref.watch(publicTripsForYouProvider(code)).value;
    if (trips == null || trips.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Same heading as Home's other sections: small blue label, title.
          Text(
            'FROM OTHER EXPLORERS',
            style: AppTypeScale.sectionLabel.copyWith(color: AppColors.accent),
          ),
          const SizedBox(height: 2),
          const Text('Trips near you', style: AppTypeScale.sectionTitle),
          const SizedBox(height: 10),
          SizedBox(
            height: PublicTripCard.height,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              itemCount: trips.length,
              separatorBuilder: (context, index) => const SizedBox(width: 10),
              itemBuilder: (context, index) => PublicTripCard(
                trip: trips[index],
                onTap: () => onOpenTrip(trips[index].id),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
