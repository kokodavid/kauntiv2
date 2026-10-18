import '../../../services/app_logger.dart';
import '../data/push_device_repository.dart';
import '../data/push_messaging_service.dart';

/// Keeps the server's record of this phone's token current, and removes it
/// on sign-out so a signed-out phone never receives the previous user's
/// notifications. Every call is best effort: a push problem must never
/// reach a screen.
class PushRegistrar {
  PushRegistrar({
    required this.service,
    required this.repository,
    required this.flavor,
    required this.appVersion,
  });

  static const _logger = AppLogger.push();

  final PushMessagingService service;
  final PushDeviceRepository? repository;
  final String flavor;
  final Future<String?> Function() appVersion;

  String? _token;

  /// Registers (or refreshes) this phone with the signed-in user. Safe to
  /// call often: on start, on resume, and when the token changes.
  Future<void> sync({String? knownToken}) => _guard('sync', () async {
    final repository = this.repository;
    if (repository == null || !await service.start()) return;
    final token = knownToken ?? await service.token();
    if (token == null) return;
    _token = token;
    await repository.register(
      token: token,
      permission: await service.permission(),
      flavor: flavor,
      appVersion: await appVersion(),
    );
  });

  /// Called just before sign-out, while the session is still valid.
  Future<void> unregister() => _guard('unregister', () async {
    final repository = this.repository;
    if (repository == null || !await service.start()) return;
    final token = _token ?? await service.token();
    if (token == null) return;
    await repository.remove(token);
    _token = null;
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
