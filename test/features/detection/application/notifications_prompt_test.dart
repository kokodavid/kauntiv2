import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaunti47_v2/src/features/auth/application/auth_providers.dart';
import 'package:kaunti47_v2/src/features/detection/application/arrival_notifier_provider.dart';
import 'package:kaunti47_v2/src/features/detection/application/notifications_prompt.dart';
import 'package:kaunti47_v2/src/features/detection/data/arrival_notifier.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeNotifier extends ArrivalNotifier {
  var permitted = false;
  var requested = 0;

  @override
  Future<bool> isPermitted() async => permitted;

  @override
  Future<bool> requestPermission() async {
    requested++;
    permitted = true;
    return true;
  }
}

void main() {
  late _FakeNotifier notifier;
  String? userId = 'alice';

  ProviderContainer container() {
    final c = ProviderContainer(
      overrides: [
        arrivalNotifierServiceProvider.overrideWithValue(notifier),
        authUserIdProvider.overrideWith((ref) => Stream.value(userId)),
        currentUserIdProvider.overrideWithValue(() => userId),
      ],
    );
    addTearDown(c.dispose);
    return c;
  }

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    notifier = _FakeNotifier();
    userId = 'alice';
  });

  test('due on first Home: not allowed yet, whatever the settings', () async {
    final c = container();
    expect(await c.read(notificationsPromptProvider.future), isTrue);
  });

  test('hidden when the phone already allows notifications', () async {
    notifier.permitted = true;
    final c = container();
    expect(await c.read(notificationsPromptProvider.future), isFalse);
  });

  test('hidden when signed out', () async {
    userId = null;
    expect(await container().read(notificationsPromptProvider.future), isFalse);
  });

  test('turning on asks the phone once, then the card goes', () async {
    final c = container();
    expect(await c.read(notificationsPromptProvider.future), isTrue);
    var settingsOpened = 0;
    await c
        .read(notificationsPromptProvider.notifier)
        .turnOn(openSettings: () => settingsOpened++);
    expect(notifier.requested, 1);
    expect(settingsOpened, 0);
    expect(await c.read(notificationsPromptProvider.future), isFalse);
  });

  test('after the phone was asked, the button opens settings', () async {
    SharedPreferences.setMockInitialValues({
      'arrival_notify.permission_asked': true,
    });
    final c = container();
    expect(await c.read(notificationsPromptProvider.future), isTrue);
    var settingsOpened = 0;
    await c
        .read(notificationsPromptProvider.notifier)
        .turnOn(openSettings: () => settingsOpened++);
    expect(notifier.requested, 0);
    expect(settingsOpened, 1);
  });

  test('dismissing hides it for good', () async {
    final c = container();
    expect(await c.read(notificationsPromptProvider.future), isTrue);
    await c.read(notificationsPromptProvider.notifier).dismiss();
    expect(c.read(notificationsPromptProvider).value, isFalse);
    expect(await container().read(notificationsPromptProvider.future), isFalse);
  });
}
