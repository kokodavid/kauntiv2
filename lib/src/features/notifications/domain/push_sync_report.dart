import 'push_destination.dart';

/// How far the last attempt to register this phone's push token got.
enum PushSyncStep {
  /// Firebase (or the server connection) was not available.
  firebase,

  /// Waiting for the phone's push token.
  token,

  /// The token was found; the server call failed.
  register,

  /// The server has this phone's token.
  registered,
}

/// The outcome of one `PushRegistrar.sync`, kept so a tester can see on the
/// phone why registration did or did not work (release logs are silent).
class PushSyncReport {
  const PushSyncReport({
    required this.at,
    required this.step,
    this.permission,
    this.token,
    this.apnsToken,
    this.detail,
  });

  final DateTime at;
  final PushSyncStep step;
  final PushPermission? permission;
  final String? token;

  /// iOS only: the token Apple handed the phone. Without it Firebase cannot
  /// produce a push token.
  final String? apnsToken;

  /// The error or reason when [step] is not [PushSyncStep.registered].
  final String? detail;

  bool get registered => step == PushSyncStep.registered;

  /// Registered and the phone allows notifications: nothing left to retry.
  bool get settled => registered && permission == PushPermission.granted;

  static String tail(String? value) =>
      value == null || value.isEmpty
      ? 'none'
      : '…${value.substring(value.length > 6 ? value.length - 6 : 0)}';
}
