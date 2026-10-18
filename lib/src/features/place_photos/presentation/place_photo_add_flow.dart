import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/place_photos_providers.dart';
import 'place_photo_submit_sheet.dart';

/// Opens the submit sheet for [placeId] and refreshes what the user's own
/// lists show afterwards. A person without a chosen username lands on the
/// "choose a username first" step; its button calls [onChooseUsername].
Future<void> startAddPhoto(
  BuildContext context,
  WidgetRef ref, {
  required String placeId,
  VoidCallback? onChooseUsername,
}) async {
  // A failed check is not a refusal: the database says no itself if needed.
  final chosen = await ref
      .read(hasChosenUsernameProvider.future)
      .then((value) => value, onError: (_) => true);
  if (!context.mounted) return;
  final result = await showPlacePhotoSubmitSheet(
    context,
    placeId: placeId,
    needsUsername: !chosen,
  );
  switch (result) {
    case PhotoSheetResult.sent:
      ref
        ..invalidate(myPlacePhotosProvider(placeId))
        ..invalidate(myPhotosProvider);
    case PhotoSheetResult.chooseUsername:
      onChooseUsername?.call();
    case null:
      break;
  }
}
