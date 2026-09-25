import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/app_type_scale.dart';
import '../../../design/app_colors.dart';
import '../application/journey_recorder.dart';
import '../domain/journey_recording.dart';
import '../domain/journey_route.dart';

/// A small pill over the tab bar while a Journey is in progress, so it's
/// never forgotten from another tab. Tapping opens its full-screen map.
class JourneyActiveBanner extends ConsumerStatefulWidget {
  const JourneyActiveBanner({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  ConsumerState<JourneyActiveBanner> createState() =>
      _JourneyActiveBannerState();
}

class _JourneyActiveBannerState extends ConsumerState<JourneyActiveBanner> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && ref.read(journeyRecorderProvider) != null) {
        setState(() {});
      }
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
    final recording =
        session.recording.phase == JourneyRecordingPhase.recording;
    final elapsed = session.recording.recordedTime(DateTime.now());
    final label = recording
        ? 'Recording · ${JourneyFormat.clock(elapsed)}'
        : 'Journey paused';
    return Semantics(
      button: true,
      label: '$label. Open the Journey map.',
      child: Material(
        color: AppColors.mapOverlayBackground,
        borderRadius: BorderRadius.circular(999),
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(999),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  recording ? Icons.fiber_manual_record : Icons.pause,
                  size: 12,
                  color: recording
                      ? AppColors.danger
                      : AppColors.mapOverlayForeground,
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: AppTypeScale.small.copyWith(
                    color: AppColors.mapOverlayForeground,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
