import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaunti47_v2/src/counties/county_paths.dart';
import 'package:kaunti47_v2/src/features/auth/application/auth_providers.dart';
import 'package:kaunti47_v2/src/features/onboarding/application/startup_flow.dart';
import 'package:kaunti47_v2/src/features/onboarding/domain/startup_state.dart';
import 'package:kaunti47_v2/src/features/profile/application/profile_setup_providers.dart';
import 'package:kaunti47_v2/src/features/profile/data/profile_setup_repository.dart';
import 'package:kaunti47_v2/src/services/app_location_permission_service.dart';

class _FakeProfile implements ProfileSetupRepository {
  CountyPath? saved;
  var failFetch = false;
  var failSave = false;

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
  String? userId;

  ProviderContainer container() {
    final c = ProviderContainer(
      overrides: [
        profileSetupRepositoryProvider.overrideWithValue(profile),
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
    userId = null;
  });

  test('the splash shows until it completes, then sign-in', () async {
    final c = container();
    final flow = c.read(startupFlowProvider.notifier);
    await flow.restoreSession();
    expect(c.read(startupFlowProvider).step, StartupStep.splash);
    flow.completeSplash();
    expect(c.read(startupFlowProvider).step, StartupStep.signIn);
  });

  test('a restored session with a county and permission is ready', () async {
    userId = 'alice';
    profile.saved = kiambu;
    final c = container();
    final flow = c.read(startupFlowProvider.notifier);
    await flow.restoreSession();
    flow.completeSplash();
    final state = c.read(startupFlowProvider);
    expect(state.step, StartupStep.ready);
    expect(state.homeCounty, kiambu);
  });

  test('no saved county asks for one, then saving checks permission', () async {
    permissions.status = AppLocationPermissionResult.denied;
    final c = container();
    final flow = c.read(startupFlowProvider.notifier)..completeSplash();
    await flow.onSignedIn();
    expect(c.read(startupFlowProvider).step, StartupStep.homeCounty);

    flow.selectCounty(kiambu);
    await flow.saveHomeCounty();
    expect(profile.saved, kiambu);
    expect(c.read(startupFlowProvider).step, StartupStep.permission);
  });

  test('a failed county check asks again with the v1 message', () async {
    profile.failFetch = true;
    final c = container();
    final flow = c.read(startupFlowProvider.notifier)..completeSplash();
    await flow.onSignedIn();
    final state = c.read(startupFlowProvider);
    expect(state.step, StartupStep.homeCounty);
    expect(state.homeCountyError, contains('Could not check'));
  });

  test('a failed save keeps the page with an error', () async {
    profile.failSave = true;
    final c = container();
    final flow = c.read(startupFlowProvider.notifier)..completeSplash();
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

  test('granting location from the page is ready', () async {
    profile.saved = kiambu;
    permissions.status = AppLocationPermissionResult.denied;
    final c = container();
    final flow = c.read(startupFlowProvider.notifier)..completeSplash();
    await flow.onSignedIn();
    expect(c.read(startupFlowProvider).step, StartupStep.permission);

    await flow.enableLocation();
    expect(c.read(startupFlowProvider).step, StartupStep.ready);
  });

  test('permanently denied opens settings; granting there resumes', () async {
    profile.saved = kiambu;
    permissions
      ..status = AppLocationPermissionResult.permanentlyDenied
      ..requestResult = AppLocationPermissionResult.permanentlyDenied;
    final c = container();
    final flow = c.read(startupFlowProvider.notifier)..completeSplash();
    await flow.onSignedIn();
    expect(c.read(startupFlowProvider).isLocationPermanentlyDenied, isTrue);

    await flow.enableLocation();
    expect(permissions.settingsOpened, 1);

    permissions.status = AppLocationPermissionResult.granted;
    await flow.recheckPermission();
    expect(c.read(startupFlowProvider).step, StartupStep.ready);
  });

  test('a denied request shows the v1 copy', () async {
    profile.saved = kiambu;
    permissions
      ..status = AppLocationPermissionResult.denied
      ..requestResult = AppLocationPermissionResult.denied;
    final c = container();
    final flow = c.read(startupFlowProvider.notifier)..completeSplash();
    await flow.onSignedIn();
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
