import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'connectivity_provider.dart';

/// A load that was refused or abandoned because the phone is offline.
class OfflineException implements Exception {
  const OfflineException();

  @override
  String toString() => 'OfflineException: no connection';
}

/// Runs a network [load] for a provider so an offline phone answers at
/// once instead of waiting out the network's own (very long) timeout.
///
/// - Already offline: throws [OfflineException] without sending anything.
/// - Looks dead on a quick check (about 2.5 s): gives up and marks the
///   phone offline.
/// - Goes offline mid-load: gives up the moment the app notices.
/// - Neither, but the server never answers: gives up after [patience].
///
/// Callers fall back to their saved copy or the offline state exactly as
/// they do for any other failed load.
Future<T> failFast<T>(
  Ref ref,
  Future<T> Function() load, {
  Duration patience = const Duration(seconds: 10),
}) => _race(
  load,
  patience: patience,
  isOffline: () => ref.read(connectivityProvider).isOffline,
  quickCheck: () => ref.read(connectivityProvider.notifier).checkNow(),
  listen: (onOffline) => ref.listen(
    connectivityProvider.select((s) => s.isOffline),
    (was, offline) => onOffline(offline),
  ),
);

/// [failFast] for a widget's own load (a detail page's `initState`).
Future<T> failFastWidget<T>(
  WidgetRef ref,
  Future<T> Function() load, {
  Duration patience = const Duration(seconds: 10),
}) => _race(
  load,
  patience: patience,
  isOffline: () => ref.read(connectivityProvider).isOffline,
  quickCheck: () => ref.read(connectivityProvider.notifier).checkNow(),
  listen: (onOffline) => ref.listenManual(
    connectivityProvider.select((s) => s.isOffline),
    (was, offline) => onOffline(offline),
  ),
);

Future<T> _race<T>(
  Future<T> Function() load, {
  required Duration patience,
  required bool Function() isOffline,
  required Future<bool> Function() quickCheck,
  required ProviderSubscription<bool> Function(void Function(bool) onOffline)
  listen,
}) async {
  if (isOffline()) throw const OfflineException();
  final gaveUp = Completer<T>();
  void giveUp() {
    if (!gaveUp.isCompleted) gaveUp.completeError(const OfflineException());
  }

  final watch = listen((offline) {
    if (offline) giveUp();
  });
  // The app still thinks it is online: ask the network now, so a dead
  // connection is found in a couple of seconds rather than ten.
  unawaited(
    quickCheck().then((reachable) {
      if (!reachable) giveUp();
    }),
  );
  try {
    return await Future.any([load(), gaveUp.future]).timeout(patience);
  } finally {
    watch.close();
    // A load that finishes after we gave up must not surface as unhandled.
    if (gaveUp.isCompleted) {
      unawaited(gaveUp.future.then((_) {}, onError: (_) {}));
    }
  }
}
