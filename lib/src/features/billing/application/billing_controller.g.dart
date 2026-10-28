// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'billing_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Runs a purchase or restore and waits for the server to confirm Pro. The
/// store says "paid" first; Supabase learns of it through the webhook a few
/// seconds later, and everything else in the app (ads, Journeys) reads Pro
/// from Supabase.

@ProviderFor(BillingController)
const billingControllerProvider = BillingControllerProvider._();

/// Runs a purchase or restore and waits for the server to confirm Pro. The
/// store says "paid" first; Supabase learns of it through the webhook a few
/// seconds later, and everything else in the app (ads, Journeys) reads Pro
/// from Supabase.
final class BillingControllerProvider
    extends $NotifierProvider<BillingController, BillingStatus> {
  /// Runs a purchase or restore and waits for the server to confirm Pro. The
  /// store says "paid" first; Supabase learns of it through the webhook a few
  /// seconds later, and everything else in the app (ads, Journeys) reads Pro
  /// from Supabase.
  const BillingControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'billingControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$billingControllerHash();

  @$internal
  @override
  BillingController create() => BillingController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(BillingStatus value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<BillingStatus>(value),
    );
  }
}

String _$billingControllerHash() => r'796211fe1baba72a392c62c9b911874d15ff1a03';

/// Runs a purchase or restore and waits for the server to confirm Pro. The
/// store says "paid" first; Supabase learns of it through the webhook a few
/// seconds later, and everything else in the app (ads, Journeys) reads Pro
/// from Supabase.

abstract class _$BillingController extends $Notifier<BillingStatus> {
  BillingStatus build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<BillingStatus, BillingStatus>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<BillingStatus, BillingStatus>,
              BillingStatus,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
