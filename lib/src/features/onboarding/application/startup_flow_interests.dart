part of 'startup_flow.dart';

/// Setup step 2 ("What do you like to see?"): the picks, saving them, the
/// skip and its Undo. Split out of [StartupFlow] to keep that file under
/// the 300-line limit; it only touches the flow's state and moves on
/// through [_continuePastInterests].
mixin _StartupInterestsSteps on _$StartupFlow {
  /// Past step 2: the permission step, or ready if location is granted.
  Future<void> _continuePastInterests();

  Future<void> _syncInterests() async {
    try {
      await ref.read(interestsRepositoryProvider).syncPending();
    } on Object {
      // Sent next time.
    }
  }

  void toggleInterest(PlaceInterest interest) {
    final next = state.interests.contains(interest)
        ? [
            for (final i in state.interests)
              if (i != interest) i,
          ]
        : PlaceInterest.withPick(state.interests, interest);
    state = state.copyWith(interests: next);
  }

  /// Step 2's Continue: remember the picks, then on to the permission.
  Future<void> continueFromInterests() async {
    if (state.isSavingInterests) return;
    await _answerInterests(state.interests, skipped: false);
  }

  /// Step 2's "Skip for now": saves an empty answer so it is never asked
  /// again in setup; step 3 shows an Undo toast.
  Future<void> skipInterests() async {
    if (state.isSavingInterests) return;
    state = state.copyWith(interests: const []);
    await _answerInterests(const [], skipped: true);
  }

  Future<void> _answerInterests(
    List<PlaceInterest> picks, {
    required bool skipped,
  }) async {
    state = state.copyWith(isSavingInterests: true);
    try {
      await ref
          .read(interestsRepositoryProvider)
          .save(InterestsAnswer(interests: picks, completed: true));
    } on Object {
      // The answer is kept on the phone; setup carries on regardless.
    }
    if (!ref.mounted) return;
    state = state.copyWith(isSavingInterests: false, interestsSkipped: skipped);
    await _continuePastInterests();
  }

  /// The Undo on the skip toast: back to step 2 with the question open.
  Future<void> undoInterestsSkip() async {
    state = state.copyWith(
      phase: StartupStep.preferences,
      interestsSkipped: false,
      permissionError: () => null,
    );
    try {
      await ref
          .read(interestsRepositoryProvider)
          .save(InterestsAnswer(interests: state.interests, completed: false));
    } on Object {
      // Still reopens; the answer is re-saved on Continue.
    }
  }

  void dismissInterestsToast() {
    if (state.interestsSkipped) {
      state = state.copyWith(interestsSkipped: false);
    }
  }
}
