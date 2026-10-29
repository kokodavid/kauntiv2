import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'pending_invite.g.dart';

/// The plan invite code from a link opened before onboarding finished.
/// Held until the user lands on the app, then opened once.
@Riverpod(keepAlive: true)
class PendingInvite extends _$PendingInvite {
  @override
  String? build() => null;

  void remember(String code) => state = code;

  void clear() => state = null;
}
