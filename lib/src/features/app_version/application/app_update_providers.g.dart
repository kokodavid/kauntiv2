// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_update_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(appUpdateRepository)
const appUpdateRepositoryProvider = AppUpdateRepositoryProvider._();

final class AppUpdateRepositoryProvider
    extends
        $FunctionalProvider<
          AppUpdateRepository,
          AppUpdateRepository,
          AppUpdateRepository
        >
    with $Provider<AppUpdateRepository> {
  const AppUpdateRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appUpdateRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appUpdateRepositoryHash();

  @$internal
  @override
  $ProviderElement<AppUpdateRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  AppUpdateRepository create(Ref ref) {
    return appUpdateRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AppUpdateRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AppUpdateRepository>(value),
    );
  }
}

String _$appUpdateRepositoryHash() =>
    r'cd3dcb4fcaed96375dad8d25bc48b4efe8fe32be';

@ProviderFor(AppUpdateController)
const appUpdateControllerProvider = AppUpdateControllerProvider._();

final class AppUpdateControllerProvider
    extends $NotifierProvider<AppUpdateController, AppUpdatePolicy?> {
  const AppUpdateControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appUpdateControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appUpdateControllerHash();

  @$internal
  @override
  AppUpdateController create() => AppUpdateController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AppUpdatePolicy? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AppUpdatePolicy?>(value),
    );
  }
}

String _$appUpdateControllerHash() =>
    r'6d3a7abad2f28527022ed069ab325fb969d0a747';

abstract class _$AppUpdateController extends $Notifier<AppUpdatePolicy?> {
  AppUpdatePolicy? build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<AppUpdatePolicy?, AppUpdatePolicy?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AppUpdatePolicy?, AppUpdatePolicy?>,
              AppUpdatePolicy?,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
