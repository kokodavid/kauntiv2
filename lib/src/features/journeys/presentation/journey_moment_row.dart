import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/app_type_scale.dart';
import '../../../core/widgets/app_save_icon.dart';
import '../../../design/app_colors.dart';
import '../../discover/application/explore_providers.dart';
import '../domain/journey_moments.dart';
import '../domain/journey_route.dart';

/// Opens Place Detail; supplied by `app/` (the `/place/:id` route).
typedef OpenJourneyPlace = void Function(BuildContext context, String id);

/// One key moment in the replay card. Place moments open the place and
/// can be saved (shared with Explore's saved state).
class JourneyMomentRow extends ConsumerWidget {
  const JourneyMomentRow({
    super.key,
    required this.moment,
    required this.time,
    this.onOpenPlace,
  });

  final JourneyMoment moment;

  /// When it happened on the Journey.
  final DateTime? time;
  final OpenJourneyPlace? onOpenPlace;

  /// Closer than this reads as "on your route".
  static const _onRouteMeters = 300.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final (icon, title, detail) = _describe(moment);
    final at = time == null
        ? null
        : TimeOfDay.fromDateTime(time!.toLocal()).format(context);
    final place = moment.place;
    final open = onOpenPlace;
    final row = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.lockedFill,
            foregroundColor: AppColors.accent,
            child: Icon(icon, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypeScale.itemTitle,
                ),
                Text(
                  at == null ? detail : '$at · $detail',
                  style: AppTypeScale.small.copyWith(
                    color: AppColors.mutedForeground,
                  ),
                ),
              ],
            ),
          ),
          if (place != null)
            AppSaveIcon(
              saved:
                  ref.watch(
                    exploreSavedPlacesProvider.select((s) => s[place.id]),
                  ) ??
                  place.saved,
              onChanged: (saved) => ref
                  .read(exploreSavedPlacesProvider.notifier)
                  .setSaved(
                    countyCode: place.countyCode,
                    placeId: place.id,
                    saved: saved,
                  ),
            ),
        ],
      ),
    );
    if (place == null || open == null) return row;
    return InkWell(
      onTap: () => open(context, place.id),
      borderRadius: BorderRadius.circular(12),
      child: row,
    );
  }

  static (IconData, String, String) _describe(JourneyMoment moment) {
    final duration = moment.duration;
    final took = duration == null ? null : JourneyFormat.duration(duration);
    final meters = moment.distanceMeters;
    final away = meters == null || meters < _onRouteMeters
        ? 'On your route'
        : '${JourneyFormat.distance(meters)} from your route';
    return switch (moment.kind) {
      JourneyMomentKind.recordingBreak => (
        Icons.pause_circle_outline,
        'Recording paused',
        took == null ? 'Picked up again later' : 'Picked up again $took later',
      ),
      JourneyMomentKind.longStop => (
        Icons.schedule,
        took == null ? 'A long stop' : 'Stopped for $took',
        'Long stop',
      ),
      JourneyMomentKind.countyCrossing => (
        Icons.flag_outlined,
        'Entered ${moment.name ?? 'a new county'}',
        'County crossing',
      ),
      JourneyMomentKind.savedPlace => (
        Icons.bookmark_outline,
        moment.name ?? 'A saved place',
        'Saved · $away',
      ),
      JourneyMomentKind.nearbyPlace => (
        Icons.place_outlined,
        moment.name ?? 'A place nearby',
        away,
      ),
    };
  }
}
