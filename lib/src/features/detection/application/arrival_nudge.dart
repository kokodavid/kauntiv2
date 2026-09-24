import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../services/app_logger.dart';
import '../../discover/application/explore_providers.dart';
import '../../discover/domain/county_detail.dart';
import '../data/arrival_nudge_history.dart';
import '../domain/arrival_nudge_rules.dart';
import '../domain/visit_models.dart';

part 'arrival_nudge.g.dart';

/// The arrival sheet's "already shown" history. Tests override it.
@Riverpod(keepAlive: true)
ArrivalNudgeHistory arrivalNudgeHistory(Ref ref) => const ArrivalNudgeHistory();

/// A crossing ready for the arrival sheet, with the county already loaded
/// so the sheet opens complete (no spinner inside it).
class PendingArrival {
  const PendingArrival({required this.nudge, required this.county});

  final CountyArrivalNudge nudge;
  final CountyDetailData county;
}

/// The crossing the app should show the arrival sheet for; null when
/// there's none. Offered by each detection cycle, taken by the sheet host.
@Riverpod(keepAlive: true)
class PendingArrivalNudge extends _$PendingArrivalNudge {
  static const _logger = AppLogger.detection();

  @override
  PendingArrival? build() => null;

  /// Picks the newest crossing among [candidates] that hasn't shown the
  /// sheet yet (never the home county) and loads its county. A failed load
  /// is logged and offered again next cycle, since nothing was marked
  /// shown.
  Future<void> offer(
    List<CountyArrivalNudge> candidates, {
    int? homeCountyCode,
  }) async {
    try {
      final nudge = ArrivalNudgeRules.pick(
        candidates,
        suppressed: {?homeCountyCode},
        shown: await ref.read(arrivalNudgeHistoryProvider).shownKeys(),
      );
      if (nudge == null || _isPending(nudge)) return;
      final county = await ref
          .read(discoverDetailRepositoryProvider)
          .countyDetail(nudge.countyCode);
      if (!ref.mounted) return;
      state = PendingArrival(nudge: nudge, county: county);
      _logger.info(
        'Arrival sheet pending for county ${nudge.countyCode} '
        'entered at ${nudge.enteredAt}.',
      );
    } on Object catch (error, stackTrace) {
      _logger.warning(
        'Could not prepare the arrival sheet.',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  /// Hands the pending crossing to the sheet: clears it and records it as
  /// shown, so the same crossing never shows twice.
  PendingArrival? take() {
    final pending = state;
    if (pending == null) return null;
    state = null;
    unawaited(ref.read(arrivalNudgeHistoryProvider).markShown(pending.nudge));
    return pending;
  }

  bool _isPending(CountyArrivalNudge nudge) {
    final pending = state?.nudge;
    return pending != null &&
        pending.countyCode == nudge.countyCode &&
        pending.enteredAt == nudge.enteredAt;
  }
}
