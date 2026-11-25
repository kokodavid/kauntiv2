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

  /// After "activating", keep checking quietly for about another minute,
  /// even if the person leaves the screen.
  static const _backgroundChecks = 12;
  static const _backgroundGap = Duration(seconds: 5);

  @override
  BillingStatus build() => BillingStatus.idle;

  /// Never starts a second purchase: while a payment is still being switched
  /// on, or the store already shows Pro, it only waits for the server.
  Future<void> buy(String planId) {
    if (state == BillingStatus.activating) return recheck();
    return _run((repository) async {
      if (await repository.hasActivePro()) return BillingOutcome.success;
      return repository.purchase(planId);
    });
  }

  /// Asks the server again whether Pro is on. Never buys anything.
  Future<void> recheck() async {
    if (state != BillingStatus.activating) return;
    state = BillingStatus.working;
    final next = await _waitForPro();
    if (ref.mounted) state = next;
  }

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
          if (state == BillingStatus.activating) unawaited(_keepChecking());
      }
    } on BillingException {
      if (ref.mounted) state = BillingStatus.failed;
    } on Object {
      if (ref.mounted) state = BillingStatus.failed;
    }
  }

  Future<void> _keepChecking() async {
    final link = ref.keepAlive();
    try {
      final next = await _waitForPro(
        checks: _backgroundChecks,
        gap: _backgroundGap,
      );
      if (ref.mounted &&
          state == BillingStatus.activating &&
          next == BillingStatus.unlocked) {
        state = BillingStatus.unlocked;
      }
    } finally {
      link.close();
    }
  }

  Future<BillingStatus> _waitForPro({
    int checks = _checks,
    Duration gap = _gap,
  }) async {
    for (var i = 0; i < checks; i++) {
      try {
        await ref.read(journeyEntitlementProvider.notifier).refreshStatus();
      } on Object {
        // Offline for a moment: try again.
      }
      if (!ref.mounted) return BillingStatus.idle;
      if (ref.read(journeyEntitlementProvider)?.active == true) {
        return BillingStatus.unlocked;
      }
      await Future<void>.delayed(gap);
      if (!ref.mounted) return BillingStatus.idle;
    }
    return BillingStatus.activating;
  }

  /// Back to the plain screen, for example after the person dismisses a
  /// message.
  void reset() => state = BillingStatus.idle;
}
