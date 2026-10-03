import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/app_type_scale.dart';
import '../domain/journey_grouping.dart';
import '../domain/journey_route.dart';
import 'journey_card.dart';
import 'journey_trip_actions.dart';

/// Opens a past Journey; mirrors journey_history_section.dart's
/// OpenJourney typedef, kept separate here to avoid importing that
/// file back (it imports this one).
typedef OpenJourney = void Function(BuildContext context, String id);

/// One month section of the Trips list: a small caps heading ("THIS
/// MONTH") with the month's own "N trips · X km" totals, over that
/// month's Trips as full-width [JourneyCard]s, newest first.
class JourneyTripGroupSection extends StatelessWidget {
  const JourneyTripGroupSection({super.key, required this.group, this.onOpen});

  final JourneyMonthGroup group;
  final OpenJourney? onOpen;

  @override
  Widget build(BuildContext context) {
    final open = onOpen;
    final uploadedCount = group.journeys.where((j) => j.isUploaded).length;
    final totals = [
      group.journeys.length == 1
          ? '1 trip'
          : '${group.journeys.length} trips',
      if (uploadedCount > 0) JourneyFormat.distance(group.totalMeters),
    ].join(' · ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(group.title.toUpperCase(), style: AppTypeScale.sectionLabel),
            ),
            Text(totals, style: AppTypeScale.small),
          ],
        ),
        const SizedBox(height: 10),
        for (final journey in group.journeys) ...[
          if (journey != group.journeys.first) const SizedBox(height: 20),
          // Consumer just for the `ref` renameJourneyTrip/deleteJourneyTrip
          // need - this section itself has no other Riverpod dependency.
          Consumer(
            builder: (context, ref, _) => JourneyCard(
              journey: journey,
              onOpen: open == null ? null : () => open(context, journey.id),
              onRename: () => renameJourneyTrip(context, ref, journey),
              onDelete: () => deleteJourneyTrip(context, ref, journey),
            ),
          ),
        ],
      ],
    );
  }
}
