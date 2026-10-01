import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../auth/application/auth_providers.dart';
import '../domain/pro_status.dart';
import 'journey_cloud_providers.dart';

part 'journey_entitlement.g.dart';

/// Cached display state for this account's monthly free-Trip usage.
@riverpod
class JourneyTrialUsage extends _$JourneyTrialUsage {
  @override
  JourneyTrialStatus? build() {
    ref.watch(authUserIdProvider);
    return null;
  }

  void update(JourneyTrialStatus status) => state = status;
}

/// Pro for starting a Journey, checked live on the server every time. No
/// cached status can start one: a Journey started on a stale "Pro" would
/// be refused at upload and stranded on the phone. The upload re-checks
/// Pro at the start time on the server as well.
@Riverpod(keepAlive: true)
class JourneyEntitlement extends _$JourneyEntitlement {
  @override
  ProStatus? build() {
    // A new account starts with no status until it's checked.
    ref.watch(authUserIdProvider);
    return null;
  }

  /// Whether a Journey may start now: Pro, or (when Pro doesn't cover it)
  /// the free Trip allowance for this month. Always returns true or
  /// throws - never a bare false - so a caller can't mistake "denied" for
  /// "not yet checked". Throws [JourneyProCheckUnavailable] when
  /// entitlement can't be checked (offline) and [JourneyTrialExhausted]
  /// when neither Pro nor the free allowance permit starting.
  Future<bool> canStart({DateTime? now}) async {
    final userId = ref.read(currentUserIdProvider)();
    if (userId == null) throw const JourneyProCheckUnavailable();
    final cloud = ref.read(supabaseJourneyRepositoryProvider);
    if (cloud == null) throw const JourneyProCheckUnavailable();
    final at = now ?? DateTime.now();
    final ProStatus status;
    try {
      status = await cloud.proStatus();
    } on Object {
      throw const JourneyProCheckUnavailable();
    }
    if (ref.read(currentUserIdProvider)() != userId) {
      throw StateError('Account changed while checking Journey access.');
    }
    if (ref.mounted) state = status;
    if (status.allowsStartAt(at)) return true;

    // Not Pro (or it lapsed): the free Trip allowance for this month
    // decides. The server is the only source of truth for the count.
    final JourneyTrialStatus trial;
    try {
      trial = await cloud.trialStatus();
    } on Object {
      throw const JourneyProCheckUnavailable();
    }
    if (ref.read(currentUserIdProvider)() != userId) {
      throw StateError('Account changed while checking Journey access.');
    }
    if (ref.mounted) ref.read(journeyTrialUsageProvider.notifier).update(trial);
    if (trial.hasRemaining) return true;
    throw const JourneyTrialExhausted();
  }

  /// Refreshes the read-only Profile status without starting a Journey.
  Future<void> refreshStatus() async {
    final userId = ref.read(currentUserIdProvider)();
    if (userId == null) return;
    final cloud = ref.read(supabaseJourneyRepositoryProvider);
    if (cloud == null) throw const JourneyProCheckUnavailable();
    final status = await cloud.proStatus();
    if (ref.read(currentUserIdProvider)() != userId) return;
    if (ref.mounted) state = status;
  }

  /// Best-effort refresh of Pro, and (only when Pro doesn't already cover
  /// starting) this month's free Trip usage, for showing an accurate
  /// usage pill before Start is tapped. Never throws: the authoritative
  /// check still happens in [canStart] when Start is actually pressed.
  Future<void> refreshAccess() async {
    try {
      await refreshStatus();
    } on Object {
      return;
    }
    final userId = ref.read(currentUserIdProvider)();
    if (userId == null) return;
    final pro = state;
    if (pro != null && pro.allowsStartAt(DateTime.now())) return;
    final cloud = ref.read(supabaseJourneyRepositoryProvider);
    if (cloud == null) return;
    try {
      final trial = await cloud.trialStatus();
      if (ref.read(currentUserIdProvider)() == userId && ref.mounted) {
        ref.read(journeyTrialUsageProvider.notifier).update(trial);
      }
    } on Object {
      // Best-effort only.
    }
  }
}
