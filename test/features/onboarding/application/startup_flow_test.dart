import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaunti47_v2/src/counties/county_paths.dart';
import 'package:kaunti47_v2/src/features/auth/application/auth_providers.dart';
import 'package:kaunti47_v2/src/features/onboarding/application/setup_progress_providers.dart';
import 'package:kaunti47_v2/src/features/onboarding/application/startup_flow.dart';
import 'package:kaunti47_v2/src/features/onboarding/data/setup_progress_store.dart';
import 'package:kaunti47_v2/src/features/onboarding/domain/startup_state.dart';
import 'package:kaunti47_v2/src/features/profile/application/interests_providers.dart';
import 'package:kaunti47_v2/src/features/profile/application/profile_settings_providers.dart';
import 'package:kaunti47_v2/src/features/profile/application/profile_setup_providers.dart';
import 'package:kaunti47_v2/src/features/profile/data/interests_repository.dart';
import 'package:kaunti47_v2/src/features/profile/data/profile_settings_repository.dart';
import 'package:kaunti47_v2/src/features/profile/data/profile_setup_repository.dart';
import 'package:kaunti47_v2/src/features/profile/domain/place_interest.dart';
import 'package:kaunti47_v2/src/features/profile/domain/profile_settings.dart';
import 'package:kaunti47_v2/src/services/app_location_permission_service.dart';

class _FakeProfile implements ProfileSetupRepository {
  CountyPath? saved;
  CountyPath? cached;
  var failFetch = false;
  var failSave = false;

  @override
  Future<CountyPath?> cachedHomeCounty() async => cached;

  @override
  Future<CountyPath?> fetchHomeCounty() async {
    if (failFetch) throw StateError('offline');
    return saved;
  }

  @override
  Future<void> saveHomeCounty(CountyPath? county) async {
    if (failSave) throw StateError('offline');
    saved = county;
  }
}

class _FakeInterests implements InterestsRepository {
  InterestsAnswer? answer;
  InterestsAnswer? saved;
  var failSave = false;

  @override
  Future<InterestsAnswer?> cached() async => answer;

  @override
  Future<InterestsAnswer?> fetch() async => answer;

  @override
  Future<void> save(InterestsAnswer a) async {
    if (failSave) throw StateError('offline');
    saved = a;
    answer = a;
  }

  @override
  Future<void> syncPending() async {}
}

class _FakeProgress implements SetupProgressStore {
  final inProgress = <String, bool>{};

  @override
  Future<bool> isInProgress(String owner) async => inProgress[owner] ?? false;

  @override
  Future<void> setInProgress(String owner, bool value) async =>
      inProgress[owner] = value;
}

class _FakeSettings implements ProfileSettingsRepository {
  final updates = <Map<String, Object?>>[];

  @override
  Future<ProfileSettings> fetch() => throw UnimplementedError();

  @override
  Future<void> update(Map<String, Object?> columns) async =>
      updates.add(columns);
}

class _FakePermissions implements AppLocationPermissionService {
  var status = AppLocationPermissionResult.granted;
  var requestResult = AppLocationPermissionResult.granted;
  var settingsOpened = 0;

  @override
  Future<AppLocationPermissionResult> checkStatus() async => status;

  @override
  Future<AppLocationPermissionResult> requestLocationAccess() async {
    status = requestResult;
    return requestResult;
  }

  @override
  Future<bool> openSettings() async {
    settingsOpened++;
    return true;
  }

  @override
  Future<bool> hasForegroundLocation() async => true;
}

void main() {
  final kiambu = CountyPaths.byCode[22]!;
  late _FakeProfile profile;
  late _FakePermissions permissions;
  late _FakeInterests interests;
  late _FakeProgress progress;
  late _FakeSettings settings;
  String? userId;

  ProviderContainer container() {
    final c = ProviderContainer(
      overrides: [
        profileSetupRepositoryProvider.overrideWithValue(profile),
        interestsRepositoryProvider.overrideWithValue(interests),
        setupProgressStoreProvider.overrideWithValue(progress),
        profileSettingsRepositoryProvider.overrideWithValue(settings),
        locationPermissionServiceProvider.overrideWithValue(permissions),
        currentUserIdProvider.overrideWithValue(() => userId),
      ],
    );
    addTearDown(c.dispose);
    return c;
  }

  setUp(() {
    profile = _FakeProfile();
    permissions = _FakePermissions();
    interests = _FakeInterests();
    progress = _FakeProgress();
    settings = _FakeSettings();
    userId = 'alice';
  });

  StartupFlow startAfterSplash(ProviderContainer c) =>
      c.read(startupFlowProvider.notifier)..completeSplash();

  test('the splash shows until it completes, then sign-in', () async {
    userId = null;
    final c = container();
    final flow = c.read(startupFlowProvider.notifier);
    await flow.restoreSession();
    expect(c.read(startupFlowProvider).step, StartupStep.splash);
    flow.completeSplash();
    expect(c.read(startupFlowProvider).step, StartupStep.signIn);
  });

  test('a returning user with a county goes straight to Home', () async {
    profile.saved = kiambu;
    permissions.status = AppLocationPermissionResult.denied;
    final c = container();
    final flow = c.read(startupFlowProvider.notifier);
    await flow.restoreSession();
    flow.completeSplash();
    final state = c.read(startupFlowProvider);
    expect(state.step, StartupStep.ready);
    expect(state.homeCounty, kiambu);
  });

  test('a remembered county starts the app even when offline', () async {
    profile
      ..cached = kiambu
      ..failFetch = true;
    final c = container();
    final flow = c.read(startupFlowProvider.notifier);
    await flow.restoreSession();
    flow.completeSplash();
    final state = c.read(startupFlowProvider);
    expect(state.step, StartupStep.ready);
    expect(state.homeCounty, kiambu);
    expect(state.homeCountyError, isNull);
  });

  test('a remembered county is replaced if the server has a new one', () async {
    final nairobi = CountyPaths.byCode[47]!;
    profile
      ..cached = kiambu
      ..saved = nairobi;
    final c = container();
    final flow = c.read(startupFlowProvider.notifier);
    await flow.restoreSession();
    await Future<void>.delayed(Duration.zero);
    expect(c.read(startupFlowProvider).homeCounty, nairobi);
  });

  test('a new user starts setup at step 1 and it is marked in progress',
      () async {
    final c = container();
    final flow = startAfterSplash(c);
    await flow.onSignedIn();
    expect(c.read(startupFlowProvider).step, StartupStep.homeCounty);
    expect(progress.inProgress['alice'], isTrue);
  });

  test('a failed county check asks again with the v1 message', () async {
    profile.failFetch = true;
    final c = container();
    final flow = startAfterSplash(c);
    await flow.onSignedIn();
    final state = c.read(startupFlowProvider);
    expect(state.step, StartupStep.homeCounty);
    expect(state.homeCountyError, contains('Could not check'));
    // Not confirmed as new, so nothing is marked in progress.
    expect(progress.inProgress['alice'], isNot(true));
  });

  test('a failed save keeps the page with an error', () async {
    profile.failSave = true;
    final c = container();
    final flow = startAfterSplash(c);
    await flow.onSignedIn();
    flow.selectCounty(kiambu);
    await flow.saveHomeCounty();
    final state = c.read(startupFlowProvider);
    expect(state.step, StartupStep.homeCounty);
    expect(
      state.homeCountyError,
      'Could not save your home county. Try again.',
    );
    expect(state.isSavingCounty, isFalse);
  });

  test('saving the county moves on to step 2', () async {
    final c = container();
    final flow = startAfterSplash(c);
    await flow.onSignedIn();
    flow.selectCounty(kiambu);
    await flow.saveHomeCounty();
    expect(profile.saved, kiambu);
    expect(c.read(startupFlowProvider).step, StartupStep.preferences);
  });

  test('picking interests saves them and moves on to the permission', () async {
    permissions.status = AppLocationPermissionResult.denied;
    final c = container();
    final flow = startAfterSplash(c);
    await flow.onSignedIn();
    flow.selectCounty(kiambu);
    await flow.saveHomeCounty();

    flow
      ..toggleInterest(PlaceInterest.coast)
      ..toggleInterest(PlaceInterest.water);
    // Kept in canonical order, whatever order they were tapped in.
    expect(c.read(startupFlowProvider).interests, [
      PlaceInterest.water,
      PlaceInterest.coast,
    ]);
    await flow.continueFromInterests();
    expect(interests.saved?.completed, isTrue);
    expect(interests.saved?.interests, [
      PlaceInterest.water,
      PlaceInterest.coast,
    ]);
    expect(c.read(startupFlowProvider).step, StartupStep.permission);
    expect(c.read(startupFlowProvider).interestsSkipped, isFalse);
  });

  test('tapping a chosen interest again removes it', () {
    final c = container();
    startAfterSplash(c)
      ..toggleInterest(PlaceInterest.food)
      ..toggleInterest(PlaceInterest.food);
    expect(c.read(startupFlowProvider).interests, isEmpty);
  });

  test('skipping saves an empty answer, shows the toast, and Undo reopens',
      () async {
    permissions.status = AppLocationPermissionResult.denied;
    final c = container();
    final flow = startAfterSplash(c);
    await flow.onSignedIn();
    flow.selectCounty(kiambu);
    await flow.saveHomeCounty();

    await flow.skipInterests();
    expect(interests.saved?.completed, isTrue);
    expect(interests.saved?.interests, isEmpty);
    var state = c.read(startupFlowProvider);
    expect(state.step, StartupStep.permission);
    expect(state.interestsSkipped, isTrue);

    await flow.undoInterestsSkip();
    state = c.read(startupFlowProvider);
    expect(state.step, StartupStep.preferences);
    expect(state.interestsSkipped, isFalse);
    expect(interests.saved?.completed, isFalse);
  });

  test('a failed interests save still moves on (kept on the phone)', () async {
    permissions.status = AppLocationPermissionResult.denied;
    interests.failSave = true;
    final c = container();
    final flow = startAfterSplash(c);
    await flow.onSignedIn();
    flow.selectCounty(kiambu);
    await flow.saveHomeCounty();
    flow.toggleInterest(PlaceInterest.views);
    await flow.continueFromInterests();
    expect(c.read(startupFlowProvider).step, StartupStep.permission);
  });

  test('back goes 3 to 2 to 1 and keeps the picks', () async {
    permissions.status = AppLocationPermissionResult.denied;
    final c = container();
    final flow = startAfterSplash(c);
    await flow.onSignedIn();
    flow.selectCounty(kiambu);
    await flow.saveHomeCounty();
    flow.toggleInterest(PlaceInterest.nature);
    await flow.continueFromInterests();

    flow.back();
    expect(c.read(startupFlowProvider).step, StartupStep.preferences);
    expect(c.read(startupFlowProvider).interests, [PlaceInterest.nature]);
    flow.back();
    expect(c.read(startupFlowProvider).step, StartupStep.homeCounty);
    flow.back();
    expect(c.read(startupFlowProvider).step, StartupStep.homeCounty);
  });

  test('reopening mid-setup resumes at step 2 when interests are open',
      () async {
    profile.cached = kiambu;
    progress.inProgress['alice'] = true;
    final c = container();
    final flow = c.read(startupFlowProvider.notifier);
    await flow.restoreSession();
    flow.completeSplash();
    expect(c.read(startupFlowProvider).step, StartupStep.preferences);
  });

  test('reopening mid-setup resumes at step 3 once interests are answered',
      () async {
    profile.cached = kiambu;
    progress.inProgress['alice'] = true;
    interests.answer = const InterestsAnswer(
      interests: [PlaceInterest.coast],
      completed: true,
    );
    permissions.status = AppLocationPermissionResult.denied;
    final c = container();
    final flow = c.read(startupFlowProvider.notifier);
    await flow.restoreSession();
    flow.completeSplash();
    final state = c.read(startupFlowProvider);
    expect(state.step, StartupStep.permission);
    expect(state.interests, [PlaceInterest.coast]);
  });

  test('granting location from step 3 finishes setup', () async {
    permissions.status = AppLocationPermissionResult.denied;
    final c = container();
    final flow = startAfterSplash(c);
    await flow.onSignedIn();
    flow.selectCounty(kiambu);
    await flow.saveHomeCounty();
    await flow.skipInterests();
    expect(c.read(startupFlowProvider).step, StartupStep.permission);

    await flow.enableLocation();
    expect(c.read(startupFlowProvider).step, StartupStep.ready);
    expect(progress.inProgress['alice'], isFalse);
  });

  test('"Not now" opens Home in manual mode and ends setup', () async {
    permissions.status = AppLocationPermissionResult.denied;
    final c = container();
    final flow = startAfterSplash(c);
    await flow.onSignedIn();
    flow.selectCounty(kiambu);
    await flow.saveHomeCounty();
    await flow.skipInterests();

    await flow.skipLocation();
    expect(c.read(startupFlowProvider).step, StartupStep.ready);
    expect(progress.inProgress['alice'], isFalse);
    expect(settings.updates, [
      {'location_mode': 'manual'},
    ]);
  });

  test('already-granted location skips the permission step', () async {
    permissions.status = AppLocationPermissionResult.granted;
    final c = container();
    final flow = startAfterSplash(c);
    await flow.onSignedIn();
    flow.selectCounty(kiambu);
    await flow.saveHomeCounty();
    await flow.skipInterests();
    expect(c.read(startupFlowProvider).step, StartupStep.ready);
  });

  test('permanently denied opens settings; granting there resumes', () async {
    permissions
      ..status = AppLocationPermissionResult.permanentlyDenied
      ..requestResult = AppLocationPermissionResult.permanentlyDenied;
    final c = container();
    final flow = startAfterSplash(c);
    await flow.onSignedIn();
    flow.selectCounty(kiambu);
    await flow.saveHomeCounty();
    await flow.skipInterests();
    expect(c.read(startupFlowProvider).isLocationPermanentlyDenied, isTrue);

    await flow.enableLocation();
    expect(permissions.settingsOpened, 1);

    permissions.status = AppLocationPermissionResult.granted;
    await flow.recheckPermission();
    expect(c.read(startupFlowProvider).step, StartupStep.ready);
  });

  test('a denied request shows the v1 copy and stays on step 3', () async {
    permissions
      ..status = AppLocationPermissionResult.denied
      ..requestResult = AppLocationPermissionResult.denied;
    final c = container();
    final flow = startAfterSplash(c);
    await flow.onSignedIn();
    flow.selectCounty(kiambu);
    await flow.saveHomeCounty();
    await flow.skipInterests();
    await flow.enableLocation();
    final state = c.read(startupFlowProvider);
    expect(state.step, StartupStep.permission);
    expect(
      state.permissionError,
      'Location permission is needed to unlock county badges automatically.',
    );
    expect(state.isRequestingLocation, isFalse);
  });
}
