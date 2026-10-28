import 'package:flutter/material.dart';

import '../../../design/app_colors.dart';
import '../domain/pro_plan.dart';

/// One selectable plan on the upgrade screen. The price text is the store's
/// own, so it is right for the storefront and needs no release to change.
class UpgradePlanCard extends StatelessWidget {
  const UpgradePlanCard({
    super.key,
    required this.plan,
    required this.selected,
    required this.onTap,
    this.savingPercent,
  });

  final ProPlan plan;
  final bool selected;
  final VoidCallback onTap;

  /// Shown as a "Save N%" badge when set (the yearly plan).
  final int? savingPercent;

  String get _name => switch (plan.period) {
    ProPlanPeriod.annual => 'Yearly',
    ProPlanPeriod.monthly => 'Monthly',
    ProPlanPeriod.other => plan.title,
  };

  String get _unit => switch (plan.period) {
    ProPlanPeriod.annual => 'per year',
    ProPlanPeriod.monthly => 'per month',
    ProPlanPeriod.other => '',
  };

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: '$_name, ${plan.priceText} $_unit',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? AppColors.accent : AppColors.cardBorder,
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                selected ? Icons.radio_button_checked : Icons.radio_button_off,
                color: selected ? AppColors.accent : AppColors.mutedForeground,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          _name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.foreground,
                          ),
                        ),
                        if (savingPercent != null) ...[
                          const SizedBox(width: 8),
                          _SavingBadge(percent: savingPercent!),
                        ],
                      ],
                    ),
                    if (_unit.isNotEmpty)
                      Text(
                        _unit,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.mutedForeground,
                        ),
                      ),
                  ],
                ),
              ),
              Text(
                plan.priceText,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.foreground,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SavingBadge extends StatelessWidget {
  const _SavingBadge({required this.percent});

  final int percent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.accent,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        'Save $percent%',
        style: const TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          color: AppColors.accentForeground,
        ),
      ),
    );
  }
}
