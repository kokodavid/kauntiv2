import 'dart:async';

import '../../../services/app_logger.dart';
import '../data/push_device_repository.dart';
import '../data/push_messaging_service.dart';
import '../domain/push_sync_report.dart';

/// Keeps the server's record of this phone's token current, and removes it
/// on sign-out so a signed-out phone never receives the previous user's
/// notifications. Every call is best effort: a push problem must never
/// reach a screen. What each sync achieved is kept in [report], for the dev
/// Push status screen and for deciding when to try again.
class PushRegistrar {
  PushRegistrar({
    required this.service,
    required this.repository,
    required this.flavor,
    required this.appVersion,
    this.tokenAttempts = 3,
    this.tokenTimeout = const Duration(seconds: 10),
    this.retryDelay = const Duration(seconds: 4),
  });

  static const _logger = AppLogger.push();

  final PushMessagingService service;
  final PushDeviceRepository? repository;
  final String flavor;
  final Future<String?> Function() appVersion;

  /// iOS hands the phone its push token a moment after permission is
  /// granted, so the token is asked for a few times before giving up.
  final int tokenAttempts;
  final Duration tokenTimeout;
  final Duration retryDelay;

  final _reports = StreamController<PushSyncReport?>.broadcast();
  PushSyncReport? _report;

  /// The outcome of the latest [sync]; null before the first one.
  PushSyncReport? get report => _report;

  /// Each new outcome, for the dev Push status screen.
  Stream<PushSyncReport?> get reports => _reports.stream;

  void _set(PushSyncReport? value) {
    _report = value;
    _reports.add(value);
  }

  String? _token;
  String? _tokenError;

  /// True once the server has this phone's token and the phone allows
  /// notifications. While false, coming back to the app syncs again.
  bool get isSettled => _report?.settled ?? false;

  /// Registers (or refreshes) this phone with the signed-in user. Safe to
  /// call often: on start, on resume, and when the token changes.
  Future<void> sync({String? knownToken}) async {
    final at = DateTime.now();
    var step = PushSyncStep.firebase;
    String? token;
    try {
      final repository = this.repository;
      if (repository == null) {
        _set(PushSyncReport(
          at: at,
          step: step,
          detail: 'No server connection in this build.',
        ));
        return;
      }
      if (!await service.start()) {
        _set(PushSyncReport(
          at: at,
          step: step,
          detail: 'Firebase did not start (settings missing or init failed).',
        ));
        return;
      }
      step = PushSyncStep.token;
      token = knownToken ?? await _fetchToken();
      if (token == null) {
        _set(PushSyncReport(
          at: at,
          step: step,
          apnsToken: await _apnsToken(),
          detail: _tokenError ?? 'Firebase returned no token.',
        ));
        return;
      }
      _token = token;
      step = PushSyncStep.register;
      final permission = await service.permission();
      await repository.register(
        token: token,
        permission: permission,
        flavor: flavor,
        appVersion: await appVersion(),
      );
      _set(PushSyncReport(
        at: at,
        step: PushSyncStep.registered,
        permission: permission,
        token: token,
        apnsToken: await _apnsToken(),
      ));
    } on Object catch (error, stackTrace) {
      _logger.warning(
        'Push (sync) failed.',
        error: error,
        stackTrace: stackTrace,
      );
      _set(PushSyncReport(
        at: at,
        step: step,
        token: token,
        detail: '$error',
      ));
    }
  }

  Future<String?> _fetchToken() async {
    _tokenError = null;
    for (var attempt = 0; attempt < tokenAttempts; attempt++) {
      if (attempt > 0) await Future<void>.delayed(retryDelay);
      try {
        final token = await service.token().timeout(tokenTimeout);
        if (token != null && token.isNotEmpty) return token;
        _tokenError = 'Firebase returned no token.';
      } on Object catch (error) {
        _tokenError = '$error';
      }
    }
    return null;
  }

  Future<String?> _apnsToken() async {
    try {
      return await service.apnsToken();
    } on Object {
      return null;
    }
  }

  /// Called just before sign-out, while the session is still valid.
  Future<void> unregister() => _guard('unregister', () async {
    final repository = this.repository;
    if (repository == null || !await service.start()) return;
    final token = _token ?? await service.token();
    if (token == null) return;
    await repository.remove(token);
    _token = null;
    _set(null);
  });

  Future<void> logOpen(String? eventId) => _guard('open', () async {
    if (eventId == null) return;
    await repository?.logOpen(eventId);
  });

  Future<void> _guard(String what, Future<void> Function() run) async {
    try {
      await run();
    } on Object catch (error, stackTrace) {
      _logger.warning(
        'Push ($what) failed.',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }
}
