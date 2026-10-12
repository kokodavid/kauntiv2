// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'last_screen.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The path of the screen the user was last on, kept by the router so a
/// bug report can say where it happened. Pages that are not part of normal
/// browsing (the feedback form itself) are not recorded.

@ProviderFor(LastScreen)
const lastScreenProvider = LastScreenProvider._();

/// The path of the screen the user was last on, kept by the router so a
/// bug report can say where it happened. Pages that are not part of normal
/// browsing (the feedback form itself) are not recorded.
final class LastScreenProvider extends $NotifierProvider<LastScreen, String?> {
  /// The path of the screen the user was last on, kept by the router so a
  /// bug report can say where it happened. Pages that are not part of normal
  /// browsing (the feedback form itself) are not recorded.
  const LastScreenProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'lastScreenProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$lastScreenHash();

  @$internal
  @override
  LastScreen create() => LastScreen();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String?>(value),
    );
  }
}

String _$lastScreenHash() => r'520705e9aef3c56d43e54c8519fedd8e627298c0';

/// The path of the screen the user was last on, kept by the router so a
/// bug report can say where it happened. Pages that are not part of normal
/// browsing (the feedback form itself) are not recorded.

abstract class _$LastScreen extends $Notifier<String?> {
  String? build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<String?, String?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<String?, String?>,
              String?,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
