// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'explore_dock_collapse_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ExploreDockCollapsed)
const exploreDockCollapsedProvider = ExploreDockCollapsedProvider._();

final class ExploreDockCollapsedProvider
    extends $NotifierProvider<ExploreDockCollapsed, bool> {
  const ExploreDockCollapsedProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'exploreDockCollapsedProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$exploreDockCollapsedHash();

  @$internal
  @override
  ExploreDockCollapsed create() => ExploreDockCollapsed();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$exploreDockCollapsedHash() =>
    r'ccb44140351a740f479b53f24983046afcb418ec';

abstract class _$ExploreDockCollapsed extends $Notifier<bool> {
  bool build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<bool, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<bool, bool>,
              bool,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
