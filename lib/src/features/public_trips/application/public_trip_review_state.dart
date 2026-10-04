import '../domain/public_trip_moment_kind.dart';
import '../domain/public_trip_owner_view.dart';

enum PublicTripReviewStage { choose, preparing, preview, submitting, submitted }

/// The most photos one public trip can show.
const publicTripMaxPhotos = 10;

/// A moment of the trip the owner can switch on or off.
class PublicTripMomentOption {
  const PublicTripMomentOption({
    required this.kind,
    required this.sequenceNumber,
    required this.detail,
  });

  final PublicTripMomentKind kind;

  /// The recorded point the moment sits at.
  final int sequenceNumber;

  /// A short description, e.g. "Entered Nyeri" or "25 min".
  final String detail;

  String get key => '${kind.wire}:$sequenceNumber';
}

/// One of the trip's uploaded photos.
class PublicTripPhotoOption {
  const PublicTripPhotoOption({required this.id, required this.url});

  final String id;

  /// A short-lived signed URL to the owner's own photo, for the picker.
  final String url;
}

class PublicTripReviewState {
  const PublicTripReviewState({
    required this.title,
    required this.trimMeters,
    required this.momentOptions,
    required this.photoOptions,
    required this.selectedMoments,
    required this.selectedPhotos,
    this.saveAsDefault = false,
    this.consent = false,
    this.stage = PublicTripReviewStage.choose,
    this.candidate,
    this.error,
  });

  final String title;
  final int trimMeters;
  final List<PublicTripMomentOption> momentOptions;
  final List<PublicTripPhotoOption> photoOptions;
  final Set<String> selectedMoments;
  final Set<String> selectedPhotos;
  final bool saveAsDefault;
  final bool consent;
  final PublicTripReviewStage stage;

  /// The sanitized preview the server built for the current choices.
  final PublicTripOwnerView? candidate;
  final String? error;

  bool get titleValid {
    final trimmed = title.trim();
    return trimmed.isNotEmpty && trimmed.length <= 80;
  }

  bool get canPrepare => titleValid && stage == PublicTripReviewStage.choose;

  bool get canSubmit {
    final view = candidate;
    return stage == PublicTripReviewStage.preview &&
        consent &&
        view != null &&
        view.hasPreview &&
        view.photosReady &&
        view.photosFailed == 0 &&
        !view.isExpired;
  }

  PublicTripReviewState copyWith({
    String? title,
    int? trimMeters,
    Set<String>? selectedMoments,
    Set<String>? selectedPhotos,
    bool? saveAsDefault,
    bool? consent,
    PublicTripReviewStage? stage,
    PublicTripOwnerView? candidate,
    String? error,
    bool clearError = false,
    bool clearCandidate = false,
  }) => PublicTripReviewState(
    title: title ?? this.title,
    trimMeters: trimMeters ?? this.trimMeters,
    momentOptions: momentOptions,
    photoOptions: photoOptions,
    selectedMoments: selectedMoments ?? this.selectedMoments,
    selectedPhotos: selectedPhotos ?? this.selectedPhotos,
    saveAsDefault: saveAsDefault ?? this.saveAsDefault,
    consent: consent ?? this.consent,
    stage: stage ?? this.stage,
    candidate: clearCandidate ? null : (candidate ?? this.candidate),
    error: clearError ? null : (error ?? this.error),
  );
}
