import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../journeys/application/journey_entitlement.dart';
import '../data/billing_repository.dart';
import '../domain/billing_status.dart';
import 'billing_providers.dart';

part 'billing_controller.g.dart';

/// Runs a purchase or restore and waits for the server to confirm Pro. The
/// store says "paid" first; Supabase learns of it through the webhook a few
/// seconds later, and everything else in the app (ads, Journeys) reads Pro
/// from Supabase.
@riverpod
class BillingController extends _$BillingController {
  /// How long to wait for the webhook before saying it is still activating.
  static const _checks = 10;
  static const _gap = Duration(seconds: 2);

  @override
  BillingStatus build() => BillingStatus.idle;

  Future<void> buy(String planId) =>
      _run((repository) => repository.purchase(planId));

  Future<void> restore() => _run((repository) => repository.restore());

  Future<void> _run(
    Future<BillingOutcome> Function(BillingRepository) action,
  ) async {
    if (state == BillingStatus.working) return;
    final repository = ref.read(billingRepositoryProvider);
    if (repository == null) return;
    state = BillingStatus.working;
    try {
      final outcome = await action(repository);
      if (!ref.mounted) return;
      switch (outcome) {
        case BillingOutcome.cancelled:
          state = BillingStatus.idle;
        case BillingOutcome.pending:
          state = BillingStatus.pending;
        case BillingOutcome.nothingFound:
          state = BillingStatus.nothingFound;
        case BillingOutcome.success:
          state = await _waitForPro();
      }
    } on BillingException {
      if (ref.mounted) state = BillingStatus.failed;
    } on Object {
      if (ref.mounted) state = BillingStatus.failed;
    }
  }

  Future<BillingStatus> _waitForPro() async {
    for (var i = 0; i < _checks; i++) {
      try {
        await ref.read(journeyEntitlementProvider.notifier).refreshStatus();
      } on Object {
        // Offline for a moment: try again.
      }
      if (!ref.mounted) return BillingStatus.idle;
      if (ref.read(journeyEntitlementProvider)?.active == true) {
        return BillingStatus.unlocked;
      }
      await Future<void>.delayed(_gap);
      if (!ref.mounted) return BillingStatus.idle;
    }
    return BillingStatus.activating;
  }

  /// Back to the plain screen, for example after the person dismisses a
  /// message.
  void reset() => state = BillingStatus.idle;
}
