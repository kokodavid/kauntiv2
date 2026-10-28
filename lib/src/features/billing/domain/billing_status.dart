/// What a purchase or restore attempt came to, from the store's side.
enum BillingOutcome { success, cancelled, pending, nothingFound }

/// Where the upgrade screen is in a purchase or restore.
enum BillingStatus {
  idle,
  working,

  /// Pro is confirmed on the server.
  unlocked,

  /// The store is waiting on approval or payment (for example a family
  /// approver). Nothing was charged yet.
  pending,

  /// Paid, but the server hasn't confirmed Pro yet. It usually follows
  /// within a minute.
  activating,
  failed,
  nothingFound,
}

/// The store or RevenueCat failed in a way the person should be told about.
class BillingException implements Exception {
  const BillingException([this.message = 'Something went wrong.']);

  final String message;

  @override
  String toString() => 'BillingException: $message';
}
