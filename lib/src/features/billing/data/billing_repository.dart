import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../domain/billing_status.dart';
import '../domain/pro_plan.dart';

/// Buying Pro through the App Store or Google Play. Supabase decides who is
/// Pro; this only starts purchases and restores.
abstract interface class BillingRepository {
  /// Tells the store layer who is buying. Must run before [plans] or
  /// [purchase], so the purchase is recorded against this account.
  Future<void> signIn(String userId);

  Future<List<ProPlan>> plans();

  Future<BillingOutcome> purchase(String planId);

  Future<BillingOutcome> restore();

  /// Whether the store layer already shows Pro for this account, for example
  /// a purchase that went through but is still being switched on. False when
  /// it cannot tell.
  Future<bool> hasActivePro();
}

class RevenueCatBillingRepository implements BillingRepository {
  RevenueCatBillingRepository({required this.apiKey});

  /// RevenueCat entitlement that means Pro.
  static const entitlementId = 'pro';

  final String apiKey;
  bool _configured = false;
  String? _signedInAs;
  final Map<String, Package> _packages = {};

  Future<void> _configure() async {
    if (_configured) return;
    await Purchases.configure(PurchasesConfiguration(apiKey));
    _configured = true;
  }

  @override
  Future<void> signIn(String userId) async {
    try {
      await _configure();
      if (_signedInAs == userId) return;
      await Purchases.logIn(userId);
      _signedInAs = userId;
    } on PlatformException catch (error) {
      throw BillingException(error.message ?? 'Could not reach the store.');
    }
  }

  @override
  Future<List<ProPlan>> plans() async {
    try {
      final offerings = await Purchases.getOfferings();
      final packages = offerings.current?.availablePackages ?? const [];
      _packages
        ..clear()
        ..addEntries(packages.map((p) => MapEntry(p.identifier, p)));
      return ProPlan.ordered(packages.map(_toPlan));
    } on PlatformException catch (error) {
      throw BillingException(error.message ?? 'Could not load the plans.');
    }
  }

  @override
  Future<BillingOutcome> purchase(String planId) async {
    final package = _packages[planId];
    if (package == null) {
      throw const BillingException('That plan is no longer available.');
    }
    try {
      final result = await Purchases.purchase(PurchaseParams.package(package));
      return _hasPro(result.customerInfo)
          ? BillingOutcome.success
          : BillingOutcome.pending;
    } on PlatformException catch (error) {
      switch (PurchasesErrorHelper.getErrorCode(error)) {
        case PurchasesErrorCode.purchaseCancelledError:
          return BillingOutcome.cancelled;
        case PurchasesErrorCode.paymentPendingError:
          return BillingOutcome.pending;
        case _:
          throw BillingException(
            error.message ?? 'The purchase could not be completed.',
          );
      }
    }
  }

  @override
  Future<BillingOutcome> restore() async {
    try {
      final info = await Purchases.restorePurchases();
      return _hasPro(info)
          ? BillingOutcome.success
          : BillingOutcome.nothingFound;
    } on PlatformException catch (error) {
      throw BillingException(
        error.message ?? 'Could not restore your purchases.',
      );
    }
  }

  @override
  Future<bool> hasActivePro() async {
    try {
      return _hasPro(await Purchases.getCustomerInfo());
    } on PlatformException {
      return false;
    }
  }

  bool _hasPro(CustomerInfo info) =>
      info.entitlements.active.containsKey(entitlementId);

  ProPlan _toPlan(Package package) {
    final product = package.storeProduct;
    return ProPlan(
      id: package.identifier,
      period: switch (package.packageType) {
        PackageType.monthly => ProPlanPeriod.monthly,
        PackageType.annual => ProPlanPeriod.annual,
        _ => ProPlanPeriod.other,
      },
      title: product.title,
      priceText: product.priceString,
      priceAmount: product.price,
    );
  }
}
