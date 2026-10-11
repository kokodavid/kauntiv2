import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/connectivity_provider.dart';

/// Rechecks the connection whenever the app comes back to the foreground,
/// and starts the provider so it is watching from launch.
class ConnectivityLifecycle extends ConsumerStatefulWidget {
  const ConnectivityLifecycle({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<ConnectivityLifecycle> createState() =>
      _ConnectivityLifecycleState();
}

class _ConnectivityLifecycleState extends ConsumerState<ConnectivityLifecycle>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(connectivityProvider.notifier).recheck();
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(connectivityProvider.select((s) => s.showsBanner));
    return widget.child;
  }
}
