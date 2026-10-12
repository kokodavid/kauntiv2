// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_version_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The installed app's version and build, like "1.0.3 (42)". Null when the
/// platform cannot say, so a screen simply shows nothing.

@ProviderFor(appVersion)
const appVersionProvider = AppVersionProvider._();

/// The installed app's version and build, like "1.0.3 (42)". Null when the
/// platform cannot say, so a screen simply shows nothing.

final class AppVersionProvider
    extends $FunctionalProvider<AsyncValue<String?>, String?, FutureOr<String?>>
    with $FutureModifier<String?>, $FutureProvider<String?> {
  /// The installed app's version and build, like "1.0.3 (42)". Null when the
  /// platform cannot say, so a screen simply shows nothing.
  const AppVersionProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appVersionProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appVersionHash();

  @$internal
  @override
  $FutureProviderElement<String?> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<String?> create(Ref ref) {
    return appVersion(ref);
  }
}

String _$appVersionHash() => r'4470c5280d216252fe825eec266f93d8744bcea3';
