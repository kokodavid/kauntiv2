import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaunti47_v2/src/features/auth/application/auth_providers.dart';
import 'package:kaunti47_v2/src/features/detection/application/arrival_notifier_provider.dart';
import 'package:kaunti47_v2/src/features/detection/application/notifications_prompt.dart';
import 'package:kaunti47_v2/src/features/detection/data/arrival_notifier.dart';
import 'package:kaunti47_v2/src/features/profile/application/interests_providers.dart';
import 'package:kaunti47_v2/src/features/profile/application/profile_settings_providers.dart';
import 'package:kaunti47_v2/src/features/profile/data/profile_settings_repository.dart';
import 'package:kaunti47_v2/src/features/profile/domain/profile_settings.dart';
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

class _FakeSettings implements ProfileSettingsRepository {
  ProfileSettings value = const ProfileSettings(
    mapVisibility: MapVisibility.friends,
    showOnLeaderboards: true,
    notifyBadgeUnlocks: true,
    notifyCountyNudges: true,
    sideQuestRadiusKm: 100,
    locationMode: LocationMode.automatic,
  );

  @override
  Future<ProfileSettings> fetch() async => value;

  @override
  Future<void> update(Map<String, Object?> columns) async {}
}

void main() {
  late _FakeNotifier notifier;
  late _FakeSettings settings;
  var sessions = 3;
  String? userId = 'alice';

  ProviderContainer container() {
    final c = ProviderContainer(
      overrides: [
        arrivalNotifierServiceProvider.overrideWithValue(notifier),
        profileSettingsRepositoryProvider.overrideWithValue(settings),
        authUserIdProvider.overrideWith((ref) => Stream.value(userId)),
        currentUserIdProvider.overrideWithValue(() => userId),
        interestsSessionCountProvider.overrideWith((ref) async => sessions),
      ],
    );
    addTearDown(c.dispose);
    return c;
  }

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    notifier = _FakeNotifier();
    settings = _FakeSettings();
    sessions = 3;
    userId = 'alice';
  });

  test('due: not allowed yet, nudges on, automatic, past session 2', () async {
    final c = container();
    expect(await c.read(notificationsPromptProvider.future), isTrue);
  });

  test('hidden when the phone already allows notifications', () async {
    notifier.permitted = true;
    final c = container();
    expect(await c.read(notificationsPromptProvider.future), isFalse);
  });

  test('hidden in the first session, and when signed out', () async {
    sessions = 1;
    expect(await container().read(notificationsPromptProvider.future), isFalse);
    sessions = 3;
    userId = null;
    expect(await container().read(notificationsPromptProvider.future), isFalse);
  });

  test('hidden with county nudges off or manual detection', () async {
    settings.value = const ProfileSettings(
      mapVisibility: MapVisibility.friends,
      showOnLeaderboards: true,
      notifyBadgeUnlocks: true,
      notifyCountyNudges: false,
      sideQuestRadiusKm: 100,
      locationMode: LocationMode.automatic,
    );
    expect(await container().read(notificationsPromptProvider.future), isFalse);
    settings.value = const ProfileSettings(
      mapVisibility: MapVisibility.friends,
      showOnLeaderboards: true,
      notifyBadgeUnlocks: true,
      notifyCountyNudges: true,
      sideQuestRadiusKm: 100,
      locationMode: LocationMode.manual,
    );
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
