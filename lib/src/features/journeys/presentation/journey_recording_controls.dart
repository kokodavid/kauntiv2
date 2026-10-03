import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/counties/county_boundary_resolver.dart';
import '../../../core/design/app_type_scale.dart';
import '../../../core/services/app_media_picker.dart';
import '../../../core/widgets/app_floating_toast.dart';
import '../../../counties/county_paths.dart';
import '../../../design/app_colors.dart';
import '../application/journey_recorder.dart';
import '../application/journey_views.dart';
import '../domain/journey_preview.dart';
import '../domain/journey_recording.dart';
import '../domain/journey_route.dart';
import '../domain/journey_summary.dart' show JourneyTitles;
import 'journey_messages.dart';
import 'journey_start_card.dart';
import 'journey_stop_dialog.dart';

part 'journey_recording_control_parts.dart';

/// The Journey in progress, collapsed to a glanceable bottom sheet over
/// the map: status, the live clock, distance and county so far, with
/// Photo / Pause-Resume / Stop as small round buttons - no text labels
/// to read, just colour and icon. "Trip details" expands it in place to
/// the Trip's name and the counties crossed so far. Shared by the
/// full-screen recording map; the Journeys tab shows its own compact
/// summary instead ([JourneyLiveCard]).
class JourneyRecordingControls extends ConsumerStatefulWidget {
  const JourneyRecordingControls({
    super.key,
    this.onOpenSettings,
    this.onExpandedChanged,
  });

  final OpenAppSettings? onOpenSettings;

  /// Reports the "Trip details" panel opening or closing, so the map
  /// above can leave it more room and keep the live position in view.
  final ValueChanged<bool>? onExpandedChanged;

  @override
  ConsumerState<JourneyRecordingControls> createState() =>
      _JourneyRecordingControlsState();
}

class _JourneyRecordingControlsState
    extends ConsumerState<JourneyRecordingControls> {
  Timer? _ticker;
  bool _busy = false;
  bool _detailsExpanded = false;

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

  void _toggleDetails() {
    setState(() => _detailsExpanded = !_detailsExpanded);
    widget.onExpandedChanged?.call(_detailsExpanded);
  }

  Future<void> _run(Future<void> Function(JourneyRecorder) action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action(ref.read(journeyRecorderProvider.notifier));
    } on Object catch (error) {
      if (!mounted) return;
      final settings = widget.onOpenSettings;
      final hasSettingsAction =
          settings != null && JourneyMessages.opensSettings(error);
      showAppToast(
        context,
        variant: AppToastVariant.error,
        title: "Couldn't update the Trip",
        message: JourneyMessages.forError(error) ?? 'Try again.',
        actionLabel: hasSettingsAction ? 'Settings' : null,
        onAction: hasSettingsAction ? settings : null,
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _confirmStop() async {
    final choice = await showJourneyStopDialog(context);
    if (!mounted) return;
    switch (choice) {
      case JourneyStopChoice.save:
        await _run((r) => r.finish());
      case JourneyStopChoice.discard:
        await _run((r) => r.discard());
      case null:
        break;
    }
  }

  Future<void> _capturePhoto() async {
    if (_busy) return;
    final AppPickedImage? photo;
    try {
      photo = await AppMediaPicker.pickImage(
        source: AppImageSource.camera,
        maxWidth: 2048,
        imageQuality: 85,
      );
    } on Object {
      if (!mounted) return;
      showAppToast(
        context,
        variant: AppToastVariant.error,
        title: "Couldn't open the camera",
      );
      return;
    }
    if (photo == null || !mounted) return;
    await _run((r) => r.captureMedia(photo!.path));
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(journeyRecorderProvider);
    if (session == null) return const SizedBox.shrink();
    final recording = session.recording;
    final isRecording = recording.phase == JourneyRecordingPhase.recording;
    final route =
        ref.watch(activeJourneyRouteProvider).value ?? JourneyRoute(const []);
    final county = journeyCountyNameForRoute(route);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Center(
          child: Container(
            width: 36,
            height: 4,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: AppColors.cardBorder,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
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
                          color: isRecording
                              ? AppColors.danger
                              : AppColors.mutedForeground,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isRecording ? 'RECORDING' : 'PAUSED',
                        style: AppTypeScale.pill.copyWith(
                          color: isRecording
                              ? AppColors.danger
                              : AppColors.mutedForeground,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    // Recorded time: stands still while paused.
                    JourneyFormat.clock(recording.recordedTime(DateTime.now())),
                    style: const TextStyle(
                      fontFamily: AppTypeScale.family,
                      fontSize: 34,
                      fontWeight: FontWeight.w700,
                      height: 1.1,
                      color: AppColors.foreground,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: JourneyFormat.distance(route.distanceMeters),
                          style: AppTypeScale.body.copyWith(
                            color: AppColors.accent,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (county != null)
                          TextSpan(
                            text: ' · $county',
                            style: AppTypeScale.body,
                          ),
                      ],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (!isRecording) ...[
                    const SizedBox(height: 8),
                    const Text(
                      "Anything between now and Resume isn't drawn, "
                      'including time the app was closed.',
                      style: AppTypeScale.small,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 10),
            if (isRecording) ...[
              _RoundButton(
                tooltip: 'Take a photo',
                onPressed: _busy ? null : _capturePhoto,
                background: AppColors.lockedFill,
                foreground: AppColors.foreground,
                icon: Icons.camera_alt_outlined,
              ),
              const SizedBox(width: 10),
            ],
            _RoundButton(
              tooltip: isRecording ? 'Pause' : 'Resume',
              onPressed: _busy
                  ? null
                  : () => _run((r) => isRecording ? r.pause() : r.resume()),
              background: isRecording
                  ? const Color(0x1F0A84FF)
                  : AppColors.accent,
              foreground: isRecording ? AppColors.accent : Colors.white,
              icon: isRecording
                  ? Icons.pause_rounded
                  : Icons.play_arrow_rounded,
            ),
            const SizedBox(width: 10),
            _RoundButton(
              tooltip: 'Stop',
              onPressed: _busy ? null : _confirmStop,
              background: const Color(0x1FFF383C),
              foreground: AppColors.danger,
              icon: Icons.stop_rounded,
            ),
          ],
        ),
        const SizedBox(height: 14),
        _TripDetailsToggle(expanded: _detailsExpanded, onTap: _toggleDetails),
        AnimatedCrossFade(
          firstChild: const SizedBox(width: double.infinity),
          secondChild: _TripDetailsPanel(
            startedAt: recording.startedAt,
            route: route,
          ),
          crossFadeState: _detailsExpanded
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 220),
          sizeCurve: Curves.easeOut,
        ),
      ],
    );
  }
}
