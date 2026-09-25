// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'router.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The app's router (architecture §5). Start-up gating is one redirect on
/// [StartupFlow]'s step; the tabs are a [StatefulShellRoute]; County and
/// Place Detail push over the shell on the root navigator.

@ProviderFor(appRouter)
const appRouterProvider = AppRouterProvider._();

/// The app's router (architecture §5). Start-up gating is one redirect on
/// [StartupFlow]'s step; the tabs are a [StatefulShellRoute]; County and
/// Place Detail push over the shell on the root navigator.

final class AppRouterProvider
    extends $FunctionalProvider<GoRouter, GoRouter, GoRouter>
    with $Provider<GoRouter> {
  /// The app's router (architecture §5). Start-up gating is one redirect on
  /// [StartupFlow]'s step; the tabs are a [StatefulShellRoute]; County and
  /// Place Detail push over the shell on the root navigator.
  const AppRouterProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appRouterProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appRouterHash();

  @$internal
  @override
  $ProviderElement<GoRouter> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  GoRouter create(Ref ref) {
    return appRouter(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GoRouter value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GoRouter>(value),
    );
  }
}

String _$appRouterHash() => r'7004d8e0168fe3a0f108ae46109286f87b6b68f0';
