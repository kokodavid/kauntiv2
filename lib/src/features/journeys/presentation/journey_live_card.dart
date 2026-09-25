import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/app_type_scale.dart';
import '../../../design/app_colors.dart';
import '../../../design/app_text_styles.dart';
import '../application/journey_recorder.dart';
import '../application/journey_views.dart';
import '../domain/journey_recording.dart';
import '../domain/journey_route.dart';
import 'journey_messages.dart';
import 'journey_stop_dialog.dart';
import 'journey_route_map.dart';
import 'journey_start_card.dart';

/// The Journey in progress: the live route, time and distance, and
/// Pause / Resume / Stop.
class JourneyLiveCard extends ConsumerStatefulWidget {
  const JourneyLiveCard({super.key, this.onOpenSettings});

  final OpenAppSettings? onOpenSettings;

  @override
  ConsumerState<JourneyLiveCard> createState() => _JourneyLiveCardState();
}

class _JourneyLiveCardState extends ConsumerState<JourneyLiveCard> {
  Timer? _ticker;
  bool _busy = false;

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

  Future<void> _run(Future<void> Function(JourneyRecorder) action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action(ref.read(journeyRecorderProvider.notifier));
    } on Object catch (error) {
      if (!mounted) return;
      final message =
          JourneyMessages.forError(error) ??
          "Couldn't update the Journey. Try again.";
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          action:
              widget.onOpenSettings != null &&
                  JourneyMessages.opensSettings(error)
              ? SnackBarAction(
                  label: 'Settings',
                  onPressed: widget.onOpenSettings!,
                )
              : null,
        ),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _confirmStop() async {
    final choice = await showJourneyStopDialog(context);
    switch (choice) {
      case JourneyStopChoice.save:
        await _run((r) => r.finish());
      case JourneyStopChoice.discard:
        await _run((r) => r.discard());
      case null:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(journeyRecorderProvider);
    if (session == null) return const SizedBox.shrink();
    final recording = session.recording;
    final isRecording = recording.phase == JourneyRecordingPhase.recording;
    final route =
        ref.watch(activeJourneyRouteProvider).value ?? JourneyRoute(const []);
    // Recorded time: stands still while paused.
    final elapsed = recording.recordedTime(DateTime.now());

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.cardBorder),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: SizedBox(
              height: 220,
              child: route.isEmpty
                  ? const _WaitingForFix()
                  : JourneyRouteMap(route: route, follow: isRecording),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _StatusRow(isRecording: isRecording),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _Stat(
                      value: JourneyFormat.clock(
                        elapsed,
                      ),
                      label: 'Elapsed',
                    ),
                    const SizedBox(width: 24),
                    _Stat(
                      value: JourneyFormat.distance(route.distanceMeters),
                      label: 'Distance',
                    ),
                  ],
                ),
                if (!isRecording) ...[
                  const SizedBox(height: 10),
                  const Text(
                    "Paused. Anything between now and Resume isn't drawn, "
                    'including time the app was closed.',
                    style: AppTypeScale.small,
                  ),
                ],
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _ControlButton(
                        label: isRecording ? 'Pause' : 'Resume',
                        filled: !isRecording,
                        onPressed: _busy
                            ? null
                            : () => _run(
                                (r) => isRecording ? r.pause() : r.resume(),
                              ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _ControlButton(
                        label: 'Stop',
                        filled: isRecording,
                        onPressed: _busy ? null : _confirmStop,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WaitingForFix extends StatelessWidget {
  const _WaitingForFix();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: AppColors.lockedFill,
      child: Center(
        child: Text('Waiting for your location…', style: AppTypeScale.small),
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({required this.isRecording});

  final bool isRecording;

  @override
  Widget build(BuildContext context) {
    final color = isRecording ? AppColors.danger : AppColors.mutedForeground;
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          isRecording ? 'Recording' : 'Paused',
          style: AppTypeScale.itemTitle.copyWith(color: color),
        ),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value, style: AppTypeScale.sectionTitle),
        Text(label, style: AppTypeScale.statLabel),
      ],
    );
  }
}

class _ControlButton extends StatelessWidget {
  const _ControlButton({
    required this.label,
    required this.filled,
    required this.onPressed,
  });

  final String label;
  final bool filled;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(24),
    );
    return SizedBox(
      height: 48,
      child: filled
          ? ElevatedButton(
              onPressed: onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: AppColors.accentForeground,
                elevation: 0,
                shape: shape,
              ),
              child: Text(label, style: AppTextStyles.buttonLabel),
            )
          : OutlinedButton(
              onPressed: onPressed,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.foreground,
                side: const BorderSide(color: AppColors.cardBorder),
                shape: shape,
              ),
              child: Text(label, style: AppTextStyles.buttonLabelSecondary),
            ),
    );
  }
}
