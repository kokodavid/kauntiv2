import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/services/fail_fast.dart';
import '../../../core/services/supabase_client_provider.dart';
import '../../auth/application/auth_providers.dart';
import '../data/place_photos_repository.dart';
import '../domain/photo_submission.dart';

part 'place_photos_providers.g.dart';

/// Null when the build has no Supabase. Tests override it.
@riverpod
PlacePhotosRepository? placePhotosRepository(Ref ref) {
  final client = ref.watch(supabaseClientProvider);
  return client == null ? null : SupabasePlacePhotosRepository(client);
}

/// Whether the dashboard has photo submissions switched on. A failed check
/// counts as off, so the card never shows when it can't be trusted.
/// Kept alive: the Add photo tile is read each time About is shown, and a
/// fresh fetch made it blink in after every tab switch.
@Riverpod(keepAlive: true)
Future<bool> placePhotosEnabled(Ref ref) async {
  ref.watch(authUserIdProvider);
  final repository = ref.watch(placePhotosRepositoryProvider);
  if (repository == null) return false;
  try {
    return await failFast(ref, repository.isEnabled);
  } on Object {
    return false;
  }
}

/// Whether the account has chosen a username; adding photos needs one.
@riverpod
Future<bool> hasChosenUsername(Ref ref) async {
  ref.watch(authUserIdProvider);
  final repository = ref.watch(placePhotosRepositoryProvider);
  if (repository == null) return false;
  return failFast(ref, repository.hasChosenUsername);
}

/// The signed-in user's submissions for one place, newest first.
@riverpod
Future<List<PhotoSubmission>> myPlacePhotos(Ref ref, String placeId) async {
  ref.watch(authUserIdProvider);
  final repository = ref.watch(placePhotosRepositoryProvider);
  if (repository == null) return const [];
  return failFast(ref, () => repository.mine(placeId: placeId));
}

/// A link to a pending submission's thumbnail (null if it can't be made).
@riverpod
Future<String?> pendingThumbnailUrl(Ref ref, String thumbPath) async {
  final repository = ref.watch(placePhotosRepositoryProvider);
  return repository?.thumbnailUrl(thumbPath);
}

/// Every submission the user has sent, across all places (My photos).
@riverpod
Future<List<PhotoSubmission>> myPhotos(Ref ref) async {
  ref.watch(authUserIdProvider);
  final repository = ref.watch(placePhotosRepositoryProvider);
  if (repository == null) return const [];
  return failFast(ref, repository.mine);
}

/// How many reviewed photos the user has not looked at (the blue dot).
/// A failed check means no dot.
@riverpod
Future<int> unseenPhotoCount(Ref ref) async {
  ref.watch(authUserIdProvider);
  final repository = ref.watch(placePhotosRepositoryProvider);
  if (repository == null) return 0;
  try {
    return await failFast(ref, repository.unseenCount);
  } on Object {
    return 0;
  }
}

/// The user's own username, for "Photo by @username" lines. Null while
/// loading or if it can't be read.
@riverpod
Future<String?> myPhotoHandle(Ref ref) async {
  ref.watch(authUserIdProvider);
  final repository = ref.watch(placePhotosRepositoryProvider);
  if (repository == null) return null;
  try {
    return await failFast(ref, repository.myHandle);
  } on Object {
    return null;
  }
}
