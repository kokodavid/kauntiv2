import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/app_type_scale.dart';
import '../../../core/domain/map_place.dart';
import '../../../core/widgets/app_photo_parts.dart';
import '../../../core/widgets/app_place_sheet.dart';
import '../../../design/app_colors.dart';
import '../application/journey_key_moments.dart';
import '../application/journey_recorder.dart';
import '../application/journey_views.dart';
import '../domain/journey_recording.dart';
import '../domain/journey_route.dart';
import 'journey_recording_controls.dart';
import 'journey_replay_controls.dart';
import 'journey_route_map.dart';
import 'journey_start_card.dart';

/// Opens the full-screen recording map; supplied by `app/`.
typedef OpenJourneyRecording = void Function(BuildContext context);

/// The Journey in progress on a full-screen map: the live route with
/// Kaunti47 places pinned as on Home (tap one for its sheet), and the
/// controls sheet docked to the bottom edge. Dragging the map stops
/// following; the re-centre button brings it back. Closes itself once
/// the Journey is saved or discarded; minimising keeps it recording.
class JourneyRecordingScreen extends ConsumerStatefulWidget {
  const JourneyRecordingScreen({
    super.key,
    this.onOpenSettings,
    this.onOpenPlace,
    this.onRoute,
    this.onPlaceRoute,
  });

  final OpenAppSettings? onOpenSettings;
  final AppOpenPlace? onOpenPlace;
  final AppOpenDirections? onRoute;
  final AppOpenPlaceRoute? onPlaceRoute;

  @override
  ConsumerState<JourneyRecordingScreen> createState() =>
      _JourneyRecordingScreenState();
}

class _JourneyRecordingScreenState
    extends ConsumerState<JourneyRecordingScreen> {
  /// Room the camera leaves for the collapsed sheet.
  static const _controlsInset = 220.0;

  /// Extra room once "Trip details" is open, so the live position stays
  /// above the sheet as it grows rather than hidden behind it.
  static const _detailsInset = 150.0;

  late final Future<List<MapPlace>> _places = ref.read(
    journeyMapPlacesProvider.future,
  );
  bool _following = true;
  bool _detailsExpanded = false;

  void _showPlace(MapPlace place) => unawaited(
    AppPlaceSheet.show(
      context,
      place,
      onOpenPlace: widget.onOpenPlace,
      onRoute: widget.onRoute,
      onPlaceRoute: widget.onPlaceRoute,
    ),
  );

  @override
  Widget build(BuildContext context) {
    // Saved or discarded: nothing left to show here.
    ref.listen(journeyRecorderProvider, (previous, next) {
      if (previous != null && next == null) {
        unawaited(Navigator.of(context).maybePop());
      }
    });
    final session = ref.watch(journeyRecorderProvider);
    final isRecording =
        session?.recording.phase == JourneyRecordingPhase.recording;
    final route =
        ref.watch(activeJourneyRouteProvider).value ?? JourneyRoute(const []);
    final safeBottom = MediaQuery.paddingOf(context).bottom;
    final bottomInset =
        _controlsInset + (_detailsExpanded ? _detailsInset : 0) + safeBottom;
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (route.isEmpty)
            const ColoredBox(color: AppColors.lockedFill)
          else
            JourneyRouteMap(
              route: route,
              follow: isRecording && _following,
              bottomInset: bottomInset,
              places: _places,
              onPlaceTapped: _showPlace,
              onUserPan: () {
                if (_following) setState(() => _following = false);
              },
            ),
          SafeArea(
            child: Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: _MinimiseButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
              ),
            ),
          ),
          if (!_following && !route.isEmpty)
            JourneyMapButton(
              alignment: Alignment.topRight,
              onPressed: () => setState(() => _following = true),
              tooltip: 'Follow my route',
              icon: Icons.my_location,
            ),
          if (route.isEmpty)
            const SafeArea(
              child: Align(
                alignment: Alignment.topCenter,
                child: Padding(
                  padding: EdgeInsets.only(top: 18),
                  child: _WaitingChip(),
                ),
              ),
            ),
          Align(
            alignment: Alignment.bottomCenter,
            child: DecoratedBox(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                boxShadow: [
                  BoxShadow(
                    color: Color(0x29000000),
                    blurRadius: 24,
                    offset: Offset(0, -4),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                  child: JourneyRecordingControls(
                    onOpenSettings: widget.onOpenSettings,
                    onExpandedChanged: (expanded) =>
                        setState(() => _detailsExpanded = expanded),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The top-left "Minimise" pill: unlike [JourneyMapButton]'s icon-only
/// round shape, this one carries its own label so it reads as the way
/// back to the Trips tab rather than a settings toggle.
class _MinimiseButton extends StatelessWidget {
  const _MinimiseButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Minimise',
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: onPressed,
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.keyboard_arrow_down,
                  size: 18,
                  color: AppColors.foreground,
                ),
                SizedBox(width: 4),
                Text(
                  'Minimise',
                  style: TextStyle(
                    fontFamily: AppTypeScale.family,
                    fontSize: AppTypeScale.actionSize,
                    fontWeight: FontWeight.w600,
                    color: AppColors.foreground,
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

class _WaitingChip extends StatelessWidget {
  const _WaitingChip();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.mapOverlayBackground,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Text(
          'Waiting for your location…',
          style: AppTypeScale.small.copyWith(
            color: AppColors.mapOverlayForeground,
          ),
        ),
      ),
    );
  }
}
