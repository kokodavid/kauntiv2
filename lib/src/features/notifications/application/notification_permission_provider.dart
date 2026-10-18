import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../domain/push_destination.dart';
import 'push_providers.dart';

part 'notification_permission_provider.g.dart';

/// True when the phone has notifications switched off for Kaunti47, so
/// Settings can say so and offer a way to the phone's settings. False when
/// allowed, not asked yet, or push is not set up in this build.
@riverpod
Future<bool> notificationsBlocked(Ref ref) async {
  final permission = await ref.watch(pushMessagingServiceProvider).permission();
  return permission == PushPermission.denied;
}
