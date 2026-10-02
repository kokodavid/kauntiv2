import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/counties/county_boundary_resolver.dart';
import '../../../core/design/app_type_scale.dart';
import '../../../counties/county_paths.dart';
import '../../../design/app_colors.dart';
import '../../../design/app_text_styles.dart';
import '../application/journey_recorder.dart';
import '../application/journey_views.dart';
import '../domain/journey_recording.dart';
import '../domain/journey_route.dart';
import 'journey_recording_screen.dart';

/// The Journey in progress on the Journeys tab: a glanceable status - a
/// pulsing dot, the live clock, distance and county so far - with Open
/// handing off to the full-screen map where Pause/Resume/Stop/Photo
/// actually live. No controls duplicated here, so there's exactly one
/// place to manage a running Trip. Styled as the same solid accent
/// widget as "Record a Trip", so the Trips tab reads as one continuous
/// state rather than two different designs.
class JourneyLiveCard extends ConsumerStatefulWidget {
  const JourneyLiveCard({super.key, this.onOpenMap});

  /// The full-screen map for the Journey in progress.
  final OpenJourneyRecording? onOpenMap;

  @override
  ConsumerState<JourneyLiveCard> createState() => _JourneyLiveCardState();
}

class _JourneyLiveCardState extends ConsumerState<JourneyLiveCard> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    // Redraws the clock every second.
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(journeyRecorderProvider);
    if (session == null) return const SizedBox.shrink();
    final recording = session.recording;
    final isRecording = recording.phase == JourneyRecordingPhase.recording;
    final route =
        ref.watch(activeJourneyRouteProvider).value ?? JourneyRoute(const []);
    final dotColor = isRecording ? AppColors.danger : Colors.white;
    final county = _countyName(route);
    final open = widget.onOpenMap;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 16, 16),
      decoration: BoxDecoration(
        color: AppColors.accent,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: dotColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        '${isRecording ? 'RECORDING' : 'PAUSED'} · '
                        '${JourneyFormat.clock(recording.recordedTime(DateTime.now()))}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypeScale.pill.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  [
                    '${JourneyFormat.distance(route.distanceMeters)} so far',
                    if (county != null) county,
                  ].join(' · '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypeScale.small.copyWith(
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
              ],
            ),
          ),
          if (open != null) ...[
            const SizedBox(width: 12),
            ElevatedButton(
              onPressed: () => open(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.accent,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                shape: const StadiumBorder(),
              ),
              child: Text(
                'Open',
                style: AppTextStyles.buttonLabel.copyWith(
                  color: AppColors.accent,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// The county the live route's last recorded point is in, from the
  /// bundled boundaries (so it works offline too) - null until there's a
  /// fix, or outside every county's bounds.
  static String? _countyName(JourneyRoute route) {
    final last = route.lastPoint;
    if (last == null) return null;
    final code = CountyBoundaryResolver.countyCodeFor(
      latitude: last.latitude,
      longitude: last.longitude,
    );
    if (code == null) return null;
    for (final county in CountyPaths.all) {
      if (county.code == code) return county.name;
    }
    return null;
  }
}
