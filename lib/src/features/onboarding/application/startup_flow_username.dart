part of 'startup_flow.dart';

/// Setup step 3 ("Pick your explorer name"): whether to ask, and moving on
/// once it is answered or skipped. Split out of [StartupFlow] to keep that
/// file under the 300-line limit.
mixin _StartupUsernameSteps on _$StartupFlow {
  /// Past step 3: the permission step, or ready if location is granted.
  Future<void> _continuePastUsername();

  /// Only an account that has not picked a username is asked. If the check
  /// fails (offline, slow) setup carries on without the step: the generated
  /// name is safe, and publishing asks again.
  Future<bool> _shouldAskUsername() async {
    final repository = ref.read(usernameRepositoryProvider);
    if (repository == null) return false;
    try {
      return !await repository.hasChosen();
    } on Object {
      return false;
    }
  }

  /// The picker saved a username (or the user kept the one they have).
  Future<void> usernameChosen() => _continuePastUsername();

  /// "Skip for now": the generated name stays, and the first public action
  /// asks again.
  Future<void> skipUsername() => _continuePastUsername();
}
