import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/detection_controller.dart';

/// Drives [DetectionController] from the app lifecycle: a cycle on start,
/// on every resume, and every 15 s while the app is in front. The timer
/// stops in the background so the foreground location reads stop too;
/// background detection is the OS geofences' job and doesn't need it.
///
/// Wraps the signed-in, onboarded app only (location granted), so nothing
/// here runs before onboarding.
class DetectionLifecycle extends ConsumerStatefulWidget {
  const DetectionLifecycle({
    super.key,
    required this.child,
    this.homeCountyCode,
  });

  final Widget child;

  /// Fallback for the first cycle when no fix is available.
  final int? homeCountyCode;

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

  @override
  Widget build(BuildContext context) => widget.child;
}
