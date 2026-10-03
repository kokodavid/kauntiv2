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
    final county = _countyName(route);

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

  /// The county the live route's last recorded point is in, from the
  /// bundled boundaries (so it works offline too) - null until there's a
  /// fix, or outside every county's bounds. Never a fabricated
  /// neighbourhood: that's not data the app actually has.
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

/// A small tinted circle button - Photo, Pause/Resume or Stop - with no
/// text label, just an icon in its own colour over a soft tint of it.
class _RoundButton extends StatelessWidget {
  const _RoundButton({
    required this.tooltip,
    required this.onPressed,
    required this.background,
    required this.foreground,
    required this.icon,
  });

  final String tooltip;
  final VoidCallback? onPressed;
  final Color background;
  final Color foreground;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 52,
      height: 52,
      child: IconButton.filled(
        tooltip: tooltip,
        onPressed: onPressed,
        style: IconButton.styleFrom(
          backgroundColor: background,
          foregroundColor: foreground,
          disabledBackgroundColor: background,
          disabledForegroundColor: foreground.withValues(alpha: 0.4),
        ),
        icon: Icon(icon, size: 24),
      ),
    );
  }
}

/// The full-width pill under the status row: tap (or drag the handle
/// above) to reveal the Trip's name and the counties crossed so far.
class _TripDetailsToggle extends StatelessWidget {
  const _TripDetailsToggle({required this.expanded, required this.onTap});

  final bool expanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const StadiumBorder(side: BorderSide(color: AppColors.cardBorder)),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Trip details',
                style: AppTypeScale.itemTitle.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 6),
              Icon(
                expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                size: 20,
                color: AppColors.foreground,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The Trip's name and the counties crossed so far, read straight from
/// the live route (thinned the same way a static preview is, so a long
/// Trip stays cheap to scan). Renaming while recording and the photos
/// pinned along the way aren't wired up yet - both need a little more
/// plumbing than this screen alone should add.
class _TripDetailsPanel extends StatelessWidget {
  const _TripDetailsPanel({required this.startedAt, required this.route});

  final DateTime? startedAt;
  final JourneyRoute route;

  @override
  Widget build(BuildContext context) {
    final started = startedAt;
    final title = started == null
        ? 'This Trip'
        : JourneyTitles.defaultFor(started.toLocal());
    final counties = _countiesSoFar(route);
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTypeScale.cardTitle),
          const SizedBox(height: 14),
          const Text('COUNTIES SO FAR', style: AppTypeScale.sectionLabel),
          const SizedBox(height: 8),
          if (counties.isEmpty)
            const Text('Waiting for your location…', style: AppTypeScale.small)
          else
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 6,
              runSpacing: 8,
              children: [
                for (var i = 0; i < counties.length; i++) ...[
                  if (i != 0)
                    const Icon(
                      Icons.arrow_forward,
                      size: 14,
                      color: AppColors.mutedForeground,
                    ),
                  _CountyChip(
                    name: counties[i],
                    isLatest: i == counties.length - 1,
                  ),
                ],
              ],
            ),
        ],
      ),
    );
  }

  /// Counties the route has crossed so far, in order, collapsing runs of
  /// the same county into one entry. Mirrors the previous-county-first
  /// check `journey_key_moments.dart` uses, so this stays cheap even over
  /// a long Trip.
  static List<String> _countiesSoFar(JourneyRoute route) {
    if (route.isEmpty) return const [];
    final names = {
      for (final county in CountyPaths.all) county.code: county.name,
    };
    final result = <String>[];
    int? last;
    for (final segment in JourneyPreview.thin(route)) {
      for (final point in segment) {
        final previous = last;
        int? code;
        if (previous != null &&
            CountyBoundaryResolver.countyCodeFor(
                  latitude: point.latitude,
                  longitude: point.longitude,
                  countyCodes: [previous],
                  minimumInsideDistanceMeters:
                      CountyBoundaryResolver.boundaryHysteresisMeters,
                ) ==
                previous) {
          code = previous;
        } else {
          code = CountyBoundaryResolver.countyCodeFor(
            latitude: point.latitude,
            longitude: point.longitude,
            minimumInsideDistanceMeters:
                CountyBoundaryResolver.boundaryHysteresisMeters,
          );
        }
        if (code == null) continue;
        last = code;
        final name = names[code];
        if (name != null && (result.isEmpty || result.last != name)) {
          result.add(name);
        }
      }
    }
    return result;
  }
}

class _CountyChip extends StatelessWidget {
  const _CountyChip({required this.name, required this.isLatest});

  final String name;
  final bool isLatest;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isLatest ? AppColors.accent : AppColors.lockedFill,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        name,
        style: AppTypeScale.meta.copyWith(
          color: isLatest ? Colors.white : AppColors.foreground,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
