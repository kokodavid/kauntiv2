import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/arrival_nudge.dart';
import '../application/detection_controller.dart';
import 'county_arrival_sheet.dart';

/// Drives [DetectionController] from the app lifecycle: a cycle on start,
/// on every resume, and every 15 s while the app is in front. The timer
/// stops in the background so the foreground location reads stop too;
/// background detection is the OS geofences' job and doesn't need it.
///
/// It also hosts the arrival sheet: when a cycle offers a new crossing,
/// the sheet opens over whatever tab is showing (v1 listened on Home,
/// which the tab shell keeps mounted, so the effect is the same).
///
/// Wraps the signed-in, onboarded app only (location granted), so nothing
/// here runs before onboarding.
class DetectionLifecycle extends ConsumerStatefulWidget {
  const DetectionLifecycle({
    super.key,
    required this.child,
    this.homeCountyCode,
    this.onOpenCounty,
    this.onOpenPlace,
  });

  final Widget child;

  /// Fallback for the first cycle when no fix is available.
  final int? homeCountyCode;

  /// County / Place Detail from the arrival sheet, supplied by `app/`.
  final void Function(BuildContext context, int countyCode)? onOpenCounty;
  final void Function(BuildContext context, String placeId)? onOpenPlace;

  @override
  ConsumerState<DetectionLifecycle> createState() => _DetectionLifecycleState();
}

class _DetectionLifecycleState extends ConsumerState<DetectionLifecycle>
    with WidgetsBindingObserver {
  static const _interval = Duration(seconds: 15);
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _run();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _run();
      _startTimer();
    } else {
      _timer?.cancel();
      _timer = null;
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(_interval, (_) => _run());
  }

  void _run() => unawaited(
    ref
        .read(detectionControllerProvider.notifier)
        .runCycle(homeCountyCode: widget.homeCountyCode),
  );

  void _showArrival() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final pending = ref.read(pendingArrivalNudgeProvider.notifier).take();
      if (pending == null) return;
      final openCounty = widget.onOpenCounty;
      final openPlace = widget.onOpenPlace;
      unawaited(
        showCountyArrivalSheet(
          context,
          data: pending.county,
          onOpenCounty: openCounty == null
              ? null
              : (code) => openCounty(context, code),
          onOpenPlace: openPlace == null
              ? null
              : (id) => openPlace(context, id),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(pendingArrivalNudgeProvider, (previous, next) {
      if (next != null) _showArrival();
    });
    return widget.child;
  }
}
