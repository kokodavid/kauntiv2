// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pending_invite.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The plan invite code from a link opened before onboarding finished.
/// Held until the user lands on the app, then opened once.

@ProviderFor(PendingInvite)
const pendingInviteProvider = PendingInviteProvider._();

/// The plan invite code from a link opened before onboarding finished.
/// Held until the user lands on the app, then opened once.
final class PendingInviteProvider
    extends $NotifierProvider<PendingInvite, String?> {
  /// The plan invite code from a link opened before onboarding finished.
  /// Held until the user lands on the app, then opened once.
  const PendingInviteProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'pendingInviteProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$pendingInviteHash();

  @$internal
  @override
  PendingInvite create() => PendingInvite();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String?>(value),
    );
  }
}

String _$pendingInviteHash() => r'64aee2d813c5cefd5b5f74118fc3fd61cf5fa2c5';

/// The plan invite code from a link opened before onboarding finished.
/// Held until the user lands on the app, then opened once.

abstract class _$PendingInvite extends $Notifier<String?> {
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
