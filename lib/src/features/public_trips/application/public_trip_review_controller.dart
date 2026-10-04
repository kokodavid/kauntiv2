import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../journeys/application/journey_key_moments.dart';
import '../../journeys/application/journey_views.dart';
import '../domain/public_trip_failure.dart';
import '../domain/public_trip_owner_view.dart';
import '../domain/public_trip_request_id.dart';
import 'public_trip_options.dart';
import 'public_trip_providers.dart';
import 'public_trip_review_state.dart';

part 'public_trip_review_controller.g.dart';

/// The review-and-submit flow for one trip: pick moments and photos, ask
/// the server for the sanitized preview, then accept the terms and submit.
@riverpod
class PublicTripReviewController extends _$PublicTripReviewController {
  // Reused for identical choices so a retry returns the same preview rather
  // than creating another revision.
  String? _requestKey;
  String? _requestId;

  @override
  Future<PublicTripReviewState> build(String journeyId) async {
    final detail = await ref.watch(journeyDetailProvider(journeyId).future);
    final moments = await ref.watch(journeyMomentsProvider(journeyId).future);
    final media = await ref.watch(journeyMediaProvider(journeyId).future);
    // Read, not watched: editing the defaults mid-review must not reset it.
    final preferences = await ref.read(
      publicTripSharePreferencesControllerProvider.future,
    );
    final momentOptions = publicTripMomentOptions(moments);
    final photoOptions = publicTripPhotoOptions(media);
    final title = detail.summary.title.trim();
    return PublicTripReviewState(
      title: title.length > 80 ? title.substring(0, 80) : title,
      trimMeters: preferences.trimMeters,
      momentOptions: momentOptions,
      photoOptions: photoOptions,
      selectedMoments: publicTripDefaultMoments(momentOptions, preferences),
      selectedPhotos: publicTripDefaultPhotos(photoOptions, preferences),
    );
  }

  void _update(PublicTripReviewState Function(PublicTripReviewState) change) {
    final current = state.value;
    if (current != null) state = AsyncData(change(current));
  }

  void setTitle(String value) =>
      _update((s) => s.copyWith(title: value, clearError: true));

  void setTrim(int meters) =>
      _update((s) => s.copyWith(trimMeters: meters, clearError: true));

  void toggleMoment(String key) => _update((s) {
    final next = {...s.selectedMoments};
    if (!next.remove(key)) next.add(key);
    return s.copyWith(selectedMoments: next, clearError: true);
  });

  void togglePhoto(String id) => _update((s) {
    final next = {...s.selectedPhotos};
    if (!next.remove(id)) {
      if (next.length >= publicTripMaxPhotos) {
        return s.copyWith(
          error: 'You can show up to $publicTripMaxPhotos photos.',
        );
      }
      next.add(id);
    }
    return s.copyWith(selectedPhotos: next, clearError: true);
  });

  void setSaveAsDefault(bool value) =>
      _update((s) => s.copyWith(saveAsDefault: value));

  void setConsent(bool value) => _update((s) => s.copyWith(consent: value));

  /// Back from the preview to the choices (the preview is discarded).
  void backToChoices() => _update(
    (s) => s.copyWith(
      stage: PublicTripReviewStage.choose,
      consent: false,
      clearCandidate: true,
      clearError: true,
    ),
  );

  /// Asks the server for the sanitized preview of the current choices and
  /// waits for any photos to finish being prepared.
  Future<void> prepare() async {
    final current = state.value;
    if (current == null || !current.canPrepare) return;
    final repository = ref.read(publicTripRepositoryProvider);
    if (repository == null) return;
    _update(
      (s) => s.copyWith(
        stage: PublicTripReviewStage.preparing,
        clearError: true,
        clearCandidate: true,
      ),
    );
    final moments = [
      for (final option in current.momentOptions)
        if (current.selectedMoments.contains(option.key))
          (kind: option.kind.wire, sequenceNumber: option.sequenceNumber),
    ];
    final photoIds = [
      for (final option in current.photoOptions)
        if (current.selectedPhotos.contains(option.id)) option.id,
    ];
    final title = current.title.trim();
    final key = '$title|$moments|$photoIds|${current.trimMeters}';
    if (_requestKey != key) {
      _requestKey = key;
      _requestId = newPublicTripRequestId();
    }
    try {
      var view = await repository.prepare(
        journeyId: journeyId,
        requestId: _requestId!,
        title: title,
        moments: moments,
        photoIds: photoIds,
        startTrimMeters: current.trimMeters,
        endTrimMeters: current.trimMeters,
      );
      view = await _waitForPhotos(view);
      if (!ref.mounted) return;
      _update(
        (s) =>
            s.copyWith(stage: PublicTripReviewStage.preview, candidate: view),
      );
    } on PublicTripFailure catch (failure) {
      _requestKey = null; // A refused request must not be replayed.
      if (!ref.mounted) return;
      _update(
        (s) => s.copyWith(
          stage: PublicTripReviewStage.choose,
          error: failure.message,
        ),
      );
    }
  }

  /// Looks again at a preview whose photos were still being prepared.
  Future<void> refreshPhotos() async {
    final view = state.value?.candidate;
    if (view == null) return;
    try {
      final next = await _waitForPhotos(view);
      if (ref.mounted) _update((s) => s.copyWith(candidate: next));
    } on PublicTripFailure catch (failure) {
      if (ref.mounted) _update((s) => s.copyWith(error: failure.message));
    }
  }

  Future<PublicTripOwnerView> _waitForPhotos(PublicTripOwnerView first) async {
    final repository = ref.read(publicTripRepositoryProvider);
    final interval = ref.read(publicTripPhotoPollIntervalProvider);
    var view = first;
    for (var attempt = 0; view.photosPending > 0 && attempt < 40; attempt++) {
      await Future<void>.delayed(interval);
      if (!ref.mounted || repository == null) return view;
      view = await repository.mine(journeyId) ?? view;
    }
    return view;
  }

  /// Submits the previewed revision for review (with the terms accepted).
  Future<void> submit() async {
    final current = state.value;
    final view = current?.candidate;
    if (current == null || view == null || !current.canSubmit) return;
    final repository = ref.read(publicTripRepositoryProvider);
    if (repository == null) return;
    _update(
      (s) =>
          s.copyWith(stage: PublicTripReviewStage.submitting, clearError: true),
    );
    try {
      final submitted = await repository.submit(
        publicationId: view.id,
        revision: view.revision,
        contentHash: view.contentHash,
      );
      ref.invalidate(myPublicTripProvider(journeyId));
      if (current.saveAsDefault) await _saveDefaults(current);
      if (!ref.mounted) return;
      _update(
        (s) => s.copyWith(
          stage: PublicTripReviewStage.submitted,
          candidate: submitted,
        ),
      );
    } on PublicTripFailure catch (failure) {
      if (!ref.mounted) return;
      _update(
        (s) => s.copyWith(
          stage: PublicTripReviewStage.preview,
          error: failure.message,
        ),
      );
    }
  }

  /// Best effort: a failure to save defaults never undoes a submission.
  Future<void> _saveDefaults(PublicTripReviewState current) async {
    try {
      final base = await ref.read(
        publicTripSharePreferencesControllerProvider.future,
      );
      await ref
          .read(publicTripSharePreferencesControllerProvider.notifier)
          .save(
            publicTripPreferencesFromChoices(
              base: base,
              options: current.momentOptions,
              selectedMoments: current.selectedMoments,
              selectedPhotos: current.selectedPhotos,
              trimMeters: current.trimMeters,
            ),
          );
    } on Object {
      // Ignored on purpose.
    }
  }
}
