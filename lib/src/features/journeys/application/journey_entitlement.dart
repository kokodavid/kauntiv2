import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../auth/application/auth_providers.dart';
import '../domain/pro_status.dart';
import 'journey_cloud_providers.dart';

part 'journey_entitlement.g.dart';

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

  /// Whether a Journey may start now. Throws
  /// [JourneyProCheckUnavailable] when the server can't be reached.
  Future<bool> canStart({DateTime? now}) async {
    final userId = ref.read(currentUserIdProvider)();
    if (userId == null) return false;
    final cloud = ref.read(supabaseJourneyRepositoryProvider);
    if (cloud == null) return false;
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
    return status.allowsStartAt(now ?? DateTime.now());
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
}
