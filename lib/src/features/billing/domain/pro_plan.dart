/// How often a plan bills. Anything the app doesn't recognise is [other].
enum ProPlanPeriod { monthly, annual, other }

/// One Pro plan as the store describes it. Prices and wording come from the
/// store listing through RevenueCat, so changing them never needs an app
/// release.
class ProPlan {
  const ProPlan({
    required this.id,
    required this.period,
    required this.title,
    required this.priceText,
    required this.priceAmount,
  });

  /// The RevenueCat package identifier, used to start the purchase.
  final String id;
  final ProPlanPeriod period;
  final String title;

  /// The price as the store formats it for this storefront, such as
  /// "KES 199.00".
  final String priceText;

  /// The price as a number in the storefront's currency, for comparing plans.
  final double priceAmount;

  /// Annual first (the plan we want chosen), then monthly, then the rest.
  static List<ProPlan> ordered(Iterable<ProPlan> plans) {
    int rank(ProPlan plan) => switch (plan.period) {
      ProPlanPeriod.annual => 0,
      ProPlanPeriod.monthly => 1,
      ProPlanPeriod.other => 2,
    };
    final sorted = [...plans]..sort((a, b) => rank(a).compareTo(rank(b)));
    return sorted;
  }

  /// Percent saved by paying yearly instead of twelve months, or null when
  /// either plan is missing or yearly isn't cheaper.
  static int? annualSavingPercent(Iterable<ProPlan> plans) {
    ProPlan? monthly;
    ProPlan? annual;
    for (final plan in plans) {
      if (plan.period == ProPlanPeriod.monthly) monthly ??= plan;
      if (plan.period == ProPlanPeriod.annual) annual ??= plan;
    }
    if (monthly == null || annual == null || monthly.priceAmount <= 0) {
      return null;
    }
    final percent =
        ((1 - annual.priceAmount / (monthly.priceAmount * 12)) * 100).round();
    return percent > 0 ? percent : null;
  }
}
