import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/app_back_button.dart';
import '../../../core/widgets/app_floating_toast.dart';
import '../../../design/app_colors.dart';
import '../../../widgets/app_progress_indicator.dart';
import '../application/billing_controller.dart';
import '../application/billing_providers.dart';
import '../domain/billing_status.dart';
import '../domain/pro_plan.dart';
import 'upgrade_footer.dart';
import 'upgrade_plan_card.dart';

/// Where someone buys Kaunti47 Pro. Reached from Settings' Membership sheet
/// and only offered while the dashboard's billing switch is on.
class UpgradeScreen extends ConsumerStatefulWidget {
  const UpgradeScreen({super.key});

  @override
  ConsumerState<UpgradeScreen> createState() => _UpgradeScreenState();
}

class _UpgradeScreenState extends ConsumerState<UpgradeScreen> {
  static const _features = [
    'No ads',
    'Offline county maps',
    'Full journey replay & share cards',
    'Unlimited Trip history',
  ];

  String? _selectedId;

  ProPlan? _selected(List<ProPlan> plans) {
    for (final plan in plans) {
      if (plan.id == _selectedId) return plan;
    }
    return plans.isEmpty ? null : plans.first;
  }

  String? _message(BillingStatus status) => switch (status) {
    BillingStatus.pending =>
      'Your purchase is waiting for approval. Pro turns on once it goes '
          'through.',
    BillingStatus.activating =>
      'Thank you. Your payment went through and Pro is being switched on. '
          'It can take a minute.',
    BillingStatus.failed =>
      'That did not work. You have not been charged '
          'for anything that failed. Please try again.',
    BillingStatus.nothingFound =>
      'We could not find an earlier purchase for this account.',
    _ => null,
  };

  @override
  Widget build(BuildContext context) {
    ref.listen(billingControllerProvider, (_, status) {
      if (status != BillingStatus.unlocked) return;
      showAppToast(
        context,
        variant: AppToastVariant.success,
        title: 'Welcome to Pro',
      );
      unawaited(Navigator.of(context).maybePop());
    });
    final status = ref.watch(billingControllerProvider);
    final plansAsync = ref.watch(proPlansProvider);
    final working = status == BillingStatus.working;
    final activating = status == BillingStatus.activating;
    final message = _message(status);

    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: AppBackButton(
                onPressed: () => unawaited(Navigator.of(context).maybePop()),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Kaunti47 Pro',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: AppColors.foreground,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Everything in the app, with no ads.',
              style: TextStyle(color: AppColors.mutedForeground),
            ),
            const SizedBox(height: 20),
            for (final feature in _features)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    const Icon(
                      Icons.check_circle,
                      size: 18,
                      color: AppColors.accent,
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: Text(feature)),
                  ],
                ),
              ),
            const SizedBox(height: 14),
            plansAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Center(
                  child: AppProgressIndicator(
                    color: AppColors.accent,
                    radius: 14,
                  ),
                ),
              ),
              error: (_, _) => _Notice(
                text: 'We could not load the plans. Check your connection.',
                actionLabel: 'Try again',
                onAction: () => ref.invalidate(proPlansProvider),
              ),
              data: (plans) {
                if (plans.isEmpty) {
                  return const _Notice(
                    text: 'Pro is not available to buy right now.',
                  );
                }
                final selected = _selected(plans);
                final saving = ProPlan.annualSavingPercent(plans);
                return Column(
                  children: [
                    for (final plan in plans)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: UpgradePlanCard(
                          plan: plan,
                          selected: plan.id == selected?.id,
                          savingPercent: plan.period == ProPlanPeriod.annual
                              ? saving
                              : null,
                          onTap: working || activating
                              ? () {}
                              : () => setState(() => _selectedId = plan.id),
                        ),
                      ),
                    const SizedBox(height: 6),
                    FilledButton(
                      onPressed: working || selected == null
                          ? null
                          : () {
                              final controller = ref.read(
                                billingControllerProvider.notifier,
                              );
                              // Paid already: only re-check, never buy again.
                              unawaited(
                                activating
                                    ? controller.recheck()
                                    : controller.buy(selected.id),
                              );
                            },
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        foregroundColor: AppColors.accentForeground,
                        minimumSize: const Size.fromHeight(52),
                      ),
                      child: working
                          ? const AppProgressIndicator(
                              color: AppColors.accentForeground,
                            )
                          : Text(activating ? 'Check again' : 'Continue'),
                    ),
                  ],
                );
              },
            ),
            if (message != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.mutedForeground),
                ),
              ),
            const SizedBox(height: 8),
            UpgradeFooter(
              restoreEnabled: !working,
              onRestore: () => unawaited(
                ref.read(billingControllerProvider.notifier).restore(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice({required this.text, this.actionLabel, this.onAction});

  final String text;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        children: [
          Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.mutedForeground),
          ),
          if (actionLabel != null)
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(foregroundColor: AppColors.accent),
              child: Text(actionLabel!),
            ),
        ],
      ),
    );
  }
}
