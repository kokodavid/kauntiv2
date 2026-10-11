import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../domain/connectivity_state.dart';
import 'app_config_provider.dart';
import 'connectivity_probe.dart';

part 'connectivity_provider.g.dart';

/// The probe against the project's own server host.
@Riverpod(keepAlive: true)
ConnectivityProbe connectivityProbe(Ref ref) {
  final host = Uri.tryParse(ref.watch(appConfigProvider).supabaseUrl)?.host;
  return ConnectivityProbe(
    host == null || host.isEmpty ? 'one.one.one.one' : host,
  );
}

/// One app-wide answer to "are we online?". Everything offline-aware
/// (banner, notices, chips, Home's reload) reads this; nothing is shown or
/// hidden by hand. Goes offline only after a failed check is confirmed
/// 1.5 s later, so a flaky signal doesn't flicker.
@Riverpod(keepAlive: true)
class Connectivity extends _$Connectivity {
  static const confirmAfter = Duration(milliseconds: 1500);
  static const onlineEvery = Duration(seconds: 20);
  static const offlineEvery = Duration(seconds: 6);
  static const minChecking = Duration(milliseconds: 800);
  static const syncCap = Duration(seconds: 6);
  static const upToDateFor = Duration(milliseconds: 1200);

  Timer? _poll;
  Timer? _syncCap;
  Timer? _upToDate;
  bool _inFlight = false;

  @override
  ConnectivityState build() {
    ref.onDispose(() {
      _poll?.cancel();
      _syncCap?.cancel();
      _upToDate?.cancel();
    });
    // Not inside build(): state isn't set until it returns.
    Future.microtask(_tick);
    return const ConnectivityState();
  }

  Future<void> _tick() async {
    if (!ref.mounted || _inFlight) return;
    _inFlight = true;
    try {
      final ok = await _probe(confirmFailure: !state.isOffline);
      if (ref.mounted) _apply(ok);
    } finally {
      _inFlight = false;
      if (ref.mounted) {
        _poll?.cancel();
        _poll = Timer(state.isOffline ? offlineEvery : onlineEvery, _tick);
      }
    }
  }

  Future<bool> _probe({required bool confirmFailure}) async {
    final probe = ref.read(connectivityProbeProvider);
    if (await probe.reachable()) return true;
    if (!confirmFailure) return false;
    await Future<void>.delayed(confirmAfter);
    return probe.reachable();
  }

  void _apply(bool reachable) {
    if (!reachable) {
      if (state.status != ConnectivityStatus.offline) {
        state = state.copyWith(status: ConnectivityStatus.offline);
      }
      return;
    }
    if (state.isOffline) _beginReconnect();
  }

  void _beginReconnect() {
    state = state.copyWith(status: ConnectivityStatus.reconnecting);
    // The shell catches the app up (queued visits, reloads) and calls
    // [markSynced]; this is the backstop if that never reports back.
    _syncCap?.cancel();
    _syncCap = Timer(syncCap, markSynced);
  }

  /// The catch-up after a reconnect finished: shows "Up to date" briefly,
  /// then the banner leaves.
  void markSynced() {
    if (!ref.mounted || state.status != ConnectivityStatus.reconnecting) {
      return;
    }
    _syncCap?.cancel();
    state = state.copyWith(
      status: ConnectivityStatus.upToDate,
      lastSyncedAt: DateTime.now(),
    );
    _upToDate?.cancel();
    _upToDate = Timer(upToDateFor, () {
      if (ref.mounted && state.status == ConnectivityStatus.upToDate) {
        state = state.copyWith(status: ConnectivityStatus.online);
      }
    });
  }

  /// Retry: checks again now. While offline it shows "Checking..." for at
  /// least a beat so the tap visibly does something.
  Future<void> recheck() async {
    if (_inFlight) return;
    _inFlight = true;
    try {
      final wasOffline = state.isOffline;
      if (wasOffline) {
        state = state.copyWith(status: ConnectivityStatus.checking);
      }
      final results = await Future.wait([
        _probe(confirmFailure: false),
        if (wasOffline) Future<bool>.delayed(minChecking, () => true),
      ]);
      if (ref.mounted) _apply(results.first);
    } finally {
      _inFlight = false;
    }
  }
}
