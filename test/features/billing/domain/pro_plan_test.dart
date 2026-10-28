import 'package:flutter_test/flutter_test.dart';
import 'package:kaunti47_v2/src/features/billing/domain/pro_plan.dart';

ProPlan _plan(String id, ProPlanPeriod period, double amount) => ProPlan(
  id: id,
  period: period,
  title: 'Kaunti47 Pro',
  priceText: 'KES $amount',
  priceAmount: amount,
);

void main() {
  final monthly = _plan(r'$rc_monthly', ProPlanPeriod.monthly, 199);
  final annual = _plan(r'$rc_annual', ProPlanPeriod.annual, 1499);
  final other = _plan('odd', ProPlanPeriod.other, 5);

  test('annual is listed first, then monthly, then the rest', () {
    final sorted = ProPlan.ordered([other, monthly, annual]);
    expect(sorted.map((p) => p.id), [r'$rc_annual', r'$rc_monthly', 'odd']);
  });

  test('yearly saving is measured against twelve months', () {
    // 1 - 1499 / (199 * 12) = 37.2%
    expect(ProPlan.annualSavingPercent([monthly, annual]), 37);
  });

  test('no saving is shown without both plans or when yearly costs more', () {
    expect(ProPlan.annualSavingPercent([monthly]), isNull);
    expect(ProPlan.annualSavingPercent([annual]), isNull);
    final dear = _plan('dear', ProPlanPeriod.annual, 3000);
    expect(ProPlan.annualSavingPercent([monthly, dear]), isNull);
  });

  test('a free or zero-priced monthly plan never divides by zero', () {
    final free = _plan('free', ProPlanPeriod.monthly, 0);
    expect(ProPlan.annualSavingPercent([free, annual]), isNull);
  });
}
