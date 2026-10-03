import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/app_media_picker.dart';
import '../../../core/services/camera_roll_matcher.dart';
import '../../../core/widgets/app_floating_toast.dart';
import '../../auth/application/auth_providers.dart';
import '../application/journey_cloud_providers.dart';
import '../application/journey_providers.dart';
import '../application/journey_views.dart';
import '../domain/journey_summary.dart';

/// Lets the user fill a Trip's empty timeline with photos from their own
/// camera roll - the "Add photos" action on the empty-timeline card.
///
/// Uses the system photo picker ([ImagePicker.pickMultiImage]), a
/// one-tap, no-extra-permission picker, rather than scanning the whole
/// library - that's [addCameraRollMatchesToTrip]'s job, for photos the
/// camera-roll auto-match already found.
///
/// The system picker doesn't hand back a photo's original capture time
/// the way [CameraRollMatch] does, so there's no real timestamp to match
/// each photo against a route point. Rather than guess, every photo is
/// spread evenly across the Trip's recorded span in the order it was
/// picked - good enough to seed the replay with something, without
/// pretending to know when each one was actually taken.
Future<void> addJourneyPhotosToTrip(
  BuildContext context,
  WidgetRef ref,
  JourneySummary journey,
) async {
  late final List<AppPickedImage> picked;
  try {
    picked = await AppMediaPicker.pickMultiImage(
      maxWidth: 2048,
      imageQuality: 85,
    );
  } on Object {
    if (!context.mounted) return;
    showAppToast(
      context,
      variant: AppToastVariant.error,
      title: "Couldn't open your photos",
    );
    return;
  }
  if (picked.isEmpty) return;
  if (!context.mounted) return;

  final userId = ref.read(currentUserIdProvider)();
  if (userId == null) return;

  final repository = ref.read(localJourneyMediaRepositoryProvider);
  final span = journey.endedAt.difference(journey.startedAt);
  try {
    for (final (i, photo) in picked.indexed) {
      final localPath = await repository.persistPickedFile(
        journey.id,
        photo.path,
      );
      final fraction = (i + 1) / (picked.length + 1);
      await repository.add(
        journeyId: journey.id,
        userId: userId,
        localPath: localPath,
        capturedAt: journey.startedAt.add(span * fraction).toUtc(),
      );
    }
  } on Object {
    if (!context.mounted) return;
    showAppToast(
      context,
      variant: AppToastVariant.error,
      title: "Couldn't add those photos",
      message: 'Try again.',
    );
    return;
  }

  if (!context.mounted) return;
  await _uploadAndNotify(context, ref, journey.id, picked.length);
}

/// Adds camera-roll photos the auto-match already found (Claude-Design
/// "2b" reference's "Add to timeline" and "Choose" actions) - unlike
/// [addJourneyPhotosToTrip]'s manually-picked photos, these carry a real
/// capture time and, when the OS has it, a real location, both read
/// straight from [CameraRollMatch] rather than guessed.
Future<void> addCameraRollMatchesToTrip(
  BuildContext context,
  WidgetRef ref,
  JourneySummary journey,
  List<CameraRollMatch> matches,
) async {
  if (matches.isEmpty) return;

  final userId = ref.read(currentUserIdProvider)();
  if (userId == null) return;

  final repository = ref.read(localJourneyMediaRepositoryProvider);
  var added = 0;
  try {
    for (final match in matches) {
      final file = await match.asset.file;
      if (file == null) continue;
      final localPath = await repository.persistPickedFile(
        journey.id,
        file.path,
      );
      final location = await match.asset.latlngAsync();
      await repository.add(
        journeyId: journey.id,
        userId: userId,
        localPath: localPath,
        capturedAt: match.capturedAt.toUtc(),
        latitude: location?.latitude,
        longitude: location?.longitude,
      );
      added++;
    }
  } on Object {
    if (!context.mounted) return;
    showAppToast(
      context,
      variant: AppToastVariant.error,
      title: "Couldn't add those photos",
      message: 'Try again.',
    );
    return;
  }

  if (added == 0) {
    if (!context.mounted) return;
    showAppToast(
      context,
      variant: AppToastVariant.error,
      title: "Couldn't add those photos",
      message: 'They may need to finish downloading from iCloud first.',
    );
    return;
  }

  if (!context.mounted) return;
  await _uploadAndNotify(context, ref, journey.id, added);
}

/// Uploads whatever's newly queued right away rather than waiting for the
/// next background sync, so it shows up in this Replay without the user
/// having to come back later; then refreshes the screen and confirms.
/// Best-effort: a capture is already saved locally either way, and the
/// regular sync retries the upload later if this fails (e.g. offline).
Future<void> _uploadAndNotify(
  BuildContext context,
  WidgetRef ref,
  String journeyId,
  int addedCount,
) async {
  final queue = ref.read(journeyMediaUploadQueueProvider);
  if (queue != null) {
    try {
      await queue.drain();
    } on Object {
      // Ignored - handled by the normal retry/backoff on the next sync.
    }
  }
  ref.invalidate(journeyMediaProvider(journeyId));

  if (!context.mounted) return;
  showAppToast(
    context,
    variant: AppToastVariant.success,
    title: addedCount == 1
        ? 'Photo added to the Trip'
        : '$addedCount photos added to the Trip',
  );
}
