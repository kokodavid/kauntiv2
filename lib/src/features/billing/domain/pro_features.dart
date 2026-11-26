/// What Kaunti47 Pro actually unlocks, in one place so the purchase screen
/// and the Membership sheet can never drift apart.
///
/// Every line here must be something the server enforces today, because
/// App Review buys the subscription and checks what changed. Free limits
/// come from `journey_free_trial` (3 Trips a month), the Journey photo
/// quota (25) and `my_trip_plan_limits`; the Pro figures are
/// `PlanLimits.proTier`. Ad removal is deliberately absent while the `ads`
/// dashboard switch is off: nobody sees ads, so Pro cannot promise to
/// remove them. Put it back the release ads are turned on.
abstract final class ProFeatures {
  static const summary = 'More Trips, bigger plans, more room for photos.';

  static const list = [
    'Unlimited Trips each month, instead of 3',
    '50 photos a Trip, up from 25',
    'Bigger plans: 14 days, 20 stops a day',
    'Up to 6 travel buddies on a plan',
    'Best order for each day, and offline plans',
  ];
}
