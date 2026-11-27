/// ADR 0001, decision 11: a geofence event means "check here", never
/// "credit here". A county is credited only from a fix that is inside its
/// polygon, accurate enough, and, close to a border, seen twice.
///
/// Starting values; field data (issue #52) sets the final ones.
class ConfidenceGateConfig {
  const ConfidenceGateConfig({
    this.maxAccuracyMeters = 100,
    this.borderBufferMeters = 1000,
    this.confirmGap = const Duration(seconds: 10),
    this.confirmWindow = const Duration(minutes: 10),
  });

  /// A fix with a horizontal accuracy worse than this is never credited.
  final double maxAccuracyMeters;

  /// A crossing whose fix is closer than this to the county border needs a
  /// second fix in the same county before it counts.
  final double borderBufferMeters;

  /// A second fix this soon after the first is treated as the same reading.
  final Duration confirmGap;

  /// The second fix must arrive within this long of the first.
  final Duration confirmWindow;
}

enum GateVerdict {
  /// Credit the county.
  accept,

  /// Near a border: remember this fix and wait for a second one.
  needConfirmation,

  /// Too inaccurate: ignore the fix.
  reject,
}

/// The pure decision. [insideMeters] is how far inside the sampled county's
/// polygon the fix is; [alreadyPending] is whether an earlier fix in the
/// same county is waiting and still fresh.
class ConfidenceGate {
  const ConfidenceGate([this.config = const ConfidenceGateConfig()]);

  final ConfidenceGateConfig config;

  GateVerdict judge({
    required double? accuracyMeters,
    required double insideMeters,
    required bool alreadyPending,
  }) {
    if (accuracyMeters != null && accuracyMeters > config.maxAccuracyMeters) {
      return GateVerdict.reject;
    }
    // A loose fix could be on the other side of the border by its own error.
    final margin = accuracyMeters ?? 0;
    if (insideMeters - margin >= config.borderBufferMeters) {
      return GateVerdict.accept;
    }
    return alreadyPending ? GateVerdict.accept : GateVerdict.needConfirmation;
  }
}
