import 'package:flutter/material.dart';

import '../../../core/design/app_type_scale.dart';
import '../../../design/app_colors.dart';
import '../domain/journey_moments.dart';
import '../domain/journey_route.dart';
import 'journey_media_strip.dart' show openJourneyPhoto;

/// One row in the replay timeline: an icon on the connecting line, the
/// time and what happened, and - for a photo - the photo itself, shown
/// full-width rather than as a small thumbnail.
///
/// [isCurrent] lights the row up (the moment replay is paused at right
/// now); every other moment, past or still ahead, uses the same default
/// styling, so the whole Trip stays visible as one continuous story.
class JourneyTimelineMomentRow extends StatelessWidget {
  const JourneyTimelineMomentRow({
    super.key,
    required this.moment,
    required this.time,
    required this.isCurrent,
    required this.isLast,
    required this.onTap,
  });

  final JourneyMoment moment;

  /// When it happened on the Journey.
  final DateTime? time;

  /// Whether replay is paused here right now.
  final bool isCurrent;

  /// Whether this is the timeline's last row (no connecting line below).
  final bool isLast;

  /// Jumps replay to this moment's point in the route.
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final photo = moment.photo;
    final (icon, title, detail) = _describe(moment);
    final at = time == null
        ? null
        : TimeOfDay.fromDateTime(time!.toLocal()).format(context);
    final circleColor = isCurrent ? AppColors.accent : AppColors.noteBackground;
    final iconColor = isCurrent ? Colors.white : AppColors.mutedForeground;
    final titleStyle = AppTypeScale.itemTitle.copyWith(
      fontWeight: FontWeight.w600,
      color: isCurrent ? AppColors.accent : AppColors.foreground,
    );
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: circleColor,
                    foregroundColor: iconColor,
                    child: Icon(icon, size: 16),
                  ),
                  if (!isLast)
                    Expanded(
                      child: Container(
                        width: 2,
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        color: AppColors.cardBorder,
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (at != null)
                        Text(
                          at,
                          style: AppTypeScale.meta.copyWith(
                            color: AppColors.mutedForeground,
                          ),
                        ),
                      const SizedBox(height: 2),
                      Text(title, style: titleStyle),
                      if (detail.isNotEmpty) ...[
                        const SizedBox(height: 1),
                        Text(
                          detail,
                          style: AppTypeScale.small.copyWith(
                            color: AppColors.mutedForeground,
                          ),
                        ),
                      ],
                      if (photo != null) ...[
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: () => openJourneyPhoto(context, photo),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: AspectRatio(
                              aspectRatio: 16 / 10,
                              child: Image.network(
                                photo.url,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stack) =>
                                    const ColoredBox(
                                      color: AppColors.lockedFill,
                                      child: Icon(
                                        Icons.broken_image_outlined,
                                      ),
                                    ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static (IconData, String, String) _describe(JourneyMoment moment) {
    final duration = moment.duration;
    final took = duration == null ? null : JourneyFormat.duration(duration);
    return switch (moment.kind) {
      JourneyMomentKind.recordingBreak => (
        Icons.pause_circle_outline,
        'Recording paused',
        took == null ? 'Picked up again later' : 'Picked up again $took later',
      ),
      JourneyMomentKind.longStop => (
        Icons.schedule,
        took == null ? 'A long stop' : 'Stopped for $took',
        '',
      ),
      JourneyMomentKind.countyCrossing => (
        Icons.flag_outlined,
        'Entered ${moment.name ?? 'a new county'}',
        '',
      ),
      // "Photo taken" headers the row; the photo itself renders below it.
      JourneyMomentKind.photo => (Icons.photo_camera_outlined, 'Photo taken', ''),
      JourneyMomentKind.elevationPeak => (
        Icons.terrain,
        'Highest point · ${JourneyFormat.elevation(moment.elevationMeters)}',
        '',
      ),
    };
  }
}
