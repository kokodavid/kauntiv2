import 'package:flutter_test/flutter_test.dart';
import 'package:kaunti47_v2/src/features/notifications/application/push_registrar.dart';
import 'package:kaunti47_v2/src/features/notifications/data/push_device_repository.dart';
import 'package:kaunti47_v2/src/features/notifications/data/push_messaging_service.dart';
import 'package:kaunti47_v2/src/features/notifications/domain/push_destination.dart';

class _FakeService implements PushMessagingService {
  bool available = true;
  String? currentToken = 'token-1';
  PushPermission currentPermission = PushPermission.granted;

  @override
  Future<bool> start() async => available;

  @override
  Future<PushPermission> permission() async => currentPermission;

  @override
  Future<String?> token() async => currentToken;

  @override
  Future<void> deleteToken() async {}

  @override
  Stream<String> get tokenRefreshes => const Stream.empty();

  @override
  Stream<PushTap> get taps => const Stream.empty();

  @override
  Future<PushTap?> initialTap() async => null;

  @override
  Stream<PushForegroundMessage> get foreground => const Stream.empty();
}

class _FakeRepository implements PushDeviceRepository {
  final registered = <({String token, PushPermission permission})>[];
  final removed = <String>[];
  final opened = <String>[];
  bool failing = false;

  @override
  Future<void> register({
    required String token,
    required PushPermission permission,
    required String flavor,
    String? appVersion,
  }) async {
    if (failing) throw StateError('offline');
    registered.add((token: token, permission: permission));
  }

  @override
  Future<void> remove(String token) async => removed.add(token);

  @override
  Future<void> logOpen(String eventId) async => opened.add(eventId);
}

void main() {
  late _FakeService service;
  late _FakeRepository repository;
  late PushRegistrar registrar;

  setUp(() {
    service = _FakeService();
    repository = _FakeRepository();
    registrar = PushRegistrar(
      service: service,
      repository: repository,
      flavor: 'dev',
      appVersion: () async => '1.0.0 (1)',
    );
  });

  test('sync registers the token with the permission state', () async {
    service.currentPermission = PushPermission.denied;
    await registrar.sync();
    expect(repository.registered, [
      (token: 'token-1', permission: PushPermission.denied),
    ]);
  });

  test('sync does nothing when push is not available in this build', () async {
    service.available = false;
    await registrar.sync();
    expect(repository.registered, isEmpty);
  });

  test('a failing server never throws to the caller', () async {
    repository.failing = true;
    await registrar.sync();
    expect(repository.registered, isEmpty);
  });

  test('sync with a refreshed token registers that token', () async {
    await registrar.sync(knownToken: 'token-2');
    expect(repository.registered.single.token, 'token-2');
  });

  test('unregister removes the token that was registered', () async {
    await registrar.sync();
    await registrar.unregister();
    expect(repository.removed, ['token-1']);
  });

  test('logOpen skips a notification without an id', () async {
    await registrar.logOpen(null);
    await registrar.logOpen('event-1');
    expect(repository.opened, ['event-1']);
  });
}
