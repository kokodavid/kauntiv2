import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/ads/application/ads_providers.dart';

/// Starts the ads consent step once the dashboard switch is on and the
/// audience is free. Pro users, and everyone while the switch is off, never
/// reach it, so the ad SDK is never started for them.
class AdsLifecycle extends ConsumerStatefulWidget {
  const AdsLifecycle({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<AdsLifecycle> createState() => _AdsLifecycleState();
}

class _AdsLifecycleState extends ConsumerState<AdsLifecycle> {
  @override
  void initState() {
    super.initState();
    // Already wanted when the shell first appears (flag and audience loaded).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && ref.read(adsWantedProvider)) _gather();
    });
  }

  void _gather() => unawaited(ref.read(adsConsentProvider.notifier).gather());

  @override
  Widget build(BuildContext context) {
    ref.listen(adsWantedProvider, (_, wanted) {
      if (wanted) _gather();
    });
    return widget.child;
  }
}
