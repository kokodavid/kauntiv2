// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'startup_flow.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The OS location permission service. Tests override it.

@ProviderFor(locationPermissionService)
const locationPermissionServiceProvider = LocationPermissionServiceProvider._();

/// The OS location permission service. Tests override it.

final class LocationPermissionServiceProvider
    extends
        $FunctionalProvider<
          AppLocationPermissionService,
          AppLocationPermissionService,
          AppLocationPermissionService
        >
    with $Provider<AppLocationPermissionService> {
  /// The OS location permission service. Tests override it.
  const LocationPermissionServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'locationPermissionServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$locationPermissionServiceHash();

  @$internal
  @override
  $ProviderElement<AppLocationPermissionService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  AppLocationPermissionService create(Ref ref) {
    return locationPermissionService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AppLocationPermissionService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AppLocationPermissionService>(value),
    );
  }
}

String _$locationPermissionServiceHash() =>
    r'809eba6598962de8705730d4e75ca24d9648fa27';

/// Start-up and onboarding: splash (session restore) → sign in → then, for
/// a new user only, three setup steps (home county → place interests →
/// location permission) → ready. A returning user, who already has a home
/// county and no setup in progress on this phone, goes straight to ready.
/// The router redirects on [step] (`app/router.dart`); screens call these
/// methods. Ported from the old `app.dart` gate, with the same rules.

@ProviderFor(StartupFlow)
const startupFlowProvider = StartupFlowProvider._();

/// Start-up and onboarding: splash (session restore) → sign in → then, for
/// a new user only, three setup steps (home county → place interests →
/// location permission) → ready. A returning user, who already has a home
/// county and no setup in progress on this phone, goes straight to ready.
/// The router redirects on [step] (`app/router.dart`); screens call these
/// methods. Ported from the old `app.dart` gate, with the same rules.
final class StartupFlowProvider
    extends $NotifierProvider<StartupFlow, StartupState> {
  /// Start-up and onboarding: splash (session restore) → sign in → then, for
  /// a new user only, three setup steps (home county → place interests →
  /// location permission) → ready. A returning user, who already has a home
  /// county and no setup in progress on this phone, goes straight to ready.
  /// The router redirects on [step] (`app/router.dart`); screens call these
  /// methods. Ported from the old `app.dart` gate, with the same rules.
  const StartupFlowProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'startupFlowProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$startupFlowHash();

  @$internal
  @override
  StartupFlow create() => StartupFlow();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(StartupState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<StartupState>(value),
    );
  }
}

String _$startupFlowHash() => r'89958e0700d0b3dce9b2317590826e71276ad621';

/// Start-up and onboarding: splash (session restore) → sign in → then, for
/// a new user only, three setup steps (home county → place interests →
/// location permission) → ready. A returning user, who already has a home
/// county and no setup in progress on this phone, goes straight to ready.
/// The router redirects on [step] (`app/router.dart`); screens call these
/// methods. Ported from the old `app.dart` gate, with the same rules.

abstract class _$StartupFlow extends $Notifier<StartupState> {
  StartupState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<StartupState, StartupState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<StartupState, StartupState>,
              StartupState,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
