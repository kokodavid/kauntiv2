import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../services/app_logger.dart';
import '../application/journey_recorder.dart';

/// Keeps Journeys moving without the Journeys tab open:
///
/// - on start and every resume, recovers a Journey cut off by the app
///   closing (paused, waiting for Resume) and uploads finished ones;
/// - every minute while the app is in front, retries uploads. The queue's
///   own backoff decides what is due, so an idle tick is one local query,
///   and a Journey finished offline goes up within a minute of signal
///   coming back.
///
/// Stops in the background; wraps the signed-in app only.
class JourneySyncLifecycle extends ConsumerStatefulWidget {
  const JourneySyncLifecycle({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<JourneySyncLifecycle> createState() =>
      _JourneySyncLifecycleState();
}

class _JourneySyncLifecycleState extends ConsumerState<JourneySyncLifecycle>
    with WidgetsBindingObserver {
  static const _retryInterval = Duration(minutes: 1);
  static const _logger = AppLogger.journeys();
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _onForeground();
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
      _onForeground();
    } else {
      _timer?.cancel();
      _timer = null;
    }
  }

  void _onForeground() {
    unawaited(_recoverThenDrain());
    _timer?.cancel();
    _timer = Timer.periodic(_retryInterval, (_) => unawaited(_drain()));
  }

  Future<void> _recoverThenDrain() async {
    try {
      await ref.read(journeyRecorderProvider.notifier).recover();
    } on Object catch (error, stackTrace) {
      _logger.warning(
        'Journey recovery failed.',
        error: error,
        stackTrace: stackTrace,
      );
    }
    await _drain();
  }

  Future<void> _drain() async {
    try {
      await ref.read(journeySyncProvider.notifier).drain();
    } on Object catch (error, stackTrace) {
      _logger.warning(
        'Journey upload retry failed.',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
