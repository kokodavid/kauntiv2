import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/app_floating_toast.dart';
import '../application/push_providers.dart';
import '../domain/push_destination.dart';

/// Runs push for the signed-in, onboarded app: registers this phone's
/// token (on start, on resume after a while, and when it changes), turns a
/// tapped notification into a navigation, and shows a notification that
/// arrives while the app is in front as a small banner.
///
/// [onOpen] is supplied by `app/`, which owns the routes.
class PushLifecycle extends ConsumerStatefulWidget {
  const PushLifecycle({super.key, required this.child, required this.onOpen});

  final Widget child;
  final void Function(BuildContext context, PushDestination destination)
  onOpen;

  @override
  ConsumerState<PushLifecycle> createState() => _PushLifecycleState();
}

class _PushLifecycleState extends ConsumerState<PushLifecycle>
    with WidgetsBindingObserver {
  static const _resyncAfter = Duration(minutes: 30);

  final _subscriptions = <StreamSubscription<Object?>>[];
  DateTime? _lastSync;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_start());
  }

  Future<void> _start() async {
    final service = ref.read(pushMessagingServiceProvider);
    final registrar = ref.read(pushRegistrarProvider);
    _lastSync = DateTime.now();
    await registrar.sync();
    if (!mounted) return;
    _subscriptions
      ..add(
        service.tokenRefreshes.listen(
          (token) => unawaited(registrar.sync(knownToken: token)),
        ),
      )
      ..add(service.taps.listen(_open))
      ..add(service.foreground.listen(_showBanner));
    final initial = await service.initialTap();
    if (initial != null && mounted) _open(initial);
  }

  void _open(PushTap tap) {
    unawaited(ref.read(pushRegistrarProvider).logOpen(tap.eventId));
    if (!mounted) return;
    widget.onOpen(context, tap.destination);
  }

  void _showBanner(PushForegroundMessage message) {
    if (!mounted) return;
    showAppToast(
      context,
      variant: AppToastVariant.neutral,
      title: message.title,
      message: message.body,
      actionLabel: 'Open',
      onAction: () => _open(message.tap),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    final last = _lastSync;
    if (last != null && DateTime.now().difference(last) < _resyncAfter) return;
    _lastSync = DateTime.now();
    unawaited(ref.read(pushRegistrarProvider).sync());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    for (final subscription in _subscriptions) {
      unawaited(subscription.cancel());
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
