import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/auth/application/auth_providers.dart';
import '../features/detection/application/county_tracking.dart';
import '../features/journeys/application/device_motion.dart';

/// Keeps "Accurate county times" in step with the app: it steps aside while
/// a Trip records (the Trip owns location then and feeds detection itself),
/// starts again when the Trip ends or the account changes, and puts its
/// low-power settings back whenever the app goes to the background.
class CountyTrackingLifecycle extends ConsumerStatefulWidget {
  const CountyTrackingLifecycle({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<CountyTrackingLifecycle> createState() =>
      _CountyTrackingLifecycleState();
}

class _CountyTrackingLifecycleState
    extends ConsumerState<CountyTrackingLifecycle>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _sync();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _sync() => unawaited(
    ref
        .read(countyTrackingProvider.notifier)
        .sync(tripRecording: ref.read(isJourneyRecordingProvider)),
  );

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final tracking = ref.read(countyTrackingProvider.notifier);
    if (state == AppLifecycleState.paused) {
      unawaited(tracking.reapplySettings());
    } else if (state == AppLifecycleState.resumed) {
      _sync();
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(isJourneyRecordingProvider, (_, _) => _sync());
    ref.listen(authUserIdProvider, (_, _) => _sync());
    return widget.child;
  }
}
