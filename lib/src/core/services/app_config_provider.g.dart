// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_config_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The build's [AppConfig] (dev or prod). Overridden once at start-up by
/// `buildAppRoot` in `app/app_bootstrap.dart`.

@ProviderFor(appConfig)
const appConfigProvider = AppConfigProvider._();

/// The build's [AppConfig] (dev or prod). Overridden once at start-up by
/// `buildAppRoot` in `app/app_bootstrap.dart`.

final class AppConfigProvider
    extends $FunctionalProvider<AppConfig, AppConfig, AppConfig>
    with $Provider<AppConfig> {
  /// The build's [AppConfig] (dev or prod). Overridden once at start-up by
  /// `buildAppRoot` in `app/app_bootstrap.dart`.
  const AppConfigProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appConfigProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appConfigHash();

  @$internal
  @override
  $ProviderElement<AppConfig> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AppConfig create(Ref ref) {
    return appConfig(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AppConfig value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AppConfig>(value),
    );
  }
}

String _$appConfigHash() => r'fd0b5c18b44fdf6bedd5e5142f93e0ad99628ef0';
