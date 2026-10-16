// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bottom_nav_hidden_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Whether the active tab wants the floating tab bar tucked away (Explore
/// does while the traveller scrolls down or types). The shell only honours
/// it on the tab that set it, so it can never leave the bar hidden elsewhere.

@ProviderFor(BottomNavHidden)
const bottomNavHiddenProvider = BottomNavHiddenProvider._();

/// Whether the active tab wants the floating tab bar tucked away (Explore
/// does while the traveller scrolls down or types). The shell only honours
/// it on the tab that set it, so it can never leave the bar hidden elsewhere.
final class BottomNavHiddenProvider
    extends $NotifierProvider<BottomNavHidden, bool> {
  /// Whether the active tab wants the floating tab bar tucked away (Explore
  /// does while the traveller scrolls down or types). The shell only honours
  /// it on the tab that set it, so it can never leave the bar hidden elsewhere.
  const BottomNavHiddenProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'bottomNavHiddenProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$bottomNavHiddenHash();

  @$internal
  @override
  BottomNavHidden create() => BottomNavHidden();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$bottomNavHiddenHash() => r'99ee9e6ceac2d06d3825b8130a3fde164fa79a49';

/// Whether the active tab wants the floating tab bar tucked away (Explore
/// does while the traveller scrolls down or types). The shell only honours
/// it on the tab that set it, so it can never leave the bar hidden elsewhere.

abstract class _$BottomNavHidden extends $Notifier<bool> {
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
