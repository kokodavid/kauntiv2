// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'place_photos_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Null when the build has no Supabase. Tests override it.

@ProviderFor(placePhotosRepository)
const placePhotosRepositoryProvider = PlacePhotosRepositoryProvider._();

/// Null when the build has no Supabase. Tests override it.

final class PlacePhotosRepositoryProvider
    extends
        $FunctionalProvider<
          PlacePhotosRepository?,
          PlacePhotosRepository?,
          PlacePhotosRepository?
        >
    with $Provider<PlacePhotosRepository?> {
  /// Null when the build has no Supabase. Tests override it.
  const PlacePhotosRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'placePhotosRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$placePhotosRepositoryHash();

  @$internal
  @override
  $ProviderElement<PlacePhotosRepository?> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  PlacePhotosRepository? create(Ref ref) {
    return placePhotosRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PlacePhotosRepository? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PlacePhotosRepository?>(value),
    );
  }
}

String _$placePhotosRepositoryHash() =>
    r'bb461604bc6a56b9ecc80c9edeba5f8298c76cee';

/// Whether the dashboard has photo submissions switched on. A failed check
/// counts as off, so the card never shows when it can't be trusted.
/// Kept alive: the Add photo tile is read each time About is shown, and a
/// fresh fetch made it blink in after every tab switch.

@ProviderFor(placePhotosEnabled)
const placePhotosEnabledProvider = PlacePhotosEnabledProvider._();

/// Whether the dashboard has photo submissions switched on. A failed check
/// counts as off, so the card never shows when it can't be trusted.
/// Kept alive: the Add photo tile is read each time About is shown, and a
/// fresh fetch made it blink in after every tab switch.

final class PlacePhotosEnabledProvider
    extends $FunctionalProvider<AsyncValue<bool>, bool, FutureOr<bool>>
    with $FutureModifier<bool>, $FutureProvider<bool> {
  /// Whether the dashboard has photo submissions switched on. A failed check
  /// counts as off, so the card never shows when it can't be trusted.
  /// Kept alive: the Add photo tile is read each time About is shown, and a
  /// fresh fetch made it blink in after every tab switch.
  const PlacePhotosEnabledProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'placePhotosEnabledProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$placePhotosEnabledHash();

  @$internal
  @override
  $FutureProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<bool> create(Ref ref) {
    return placePhotosEnabled(ref);
  }
}

String _$placePhotosEnabledHash() =>
    r'1092a44a3ac521dc3820f402dc89726b6beb2326';

/// Whether the account has chosen a username; adding photos needs one.

@ProviderFor(hasChosenUsername)
const hasChosenUsernameProvider = HasChosenUsernameProvider._();

/// Whether the account has chosen a username; adding photos needs one.

final class HasChosenUsernameProvider
    extends $FunctionalProvider<AsyncValue<bool>, bool, FutureOr<bool>>
    with $FutureModifier<bool>, $FutureProvider<bool> {
  /// Whether the account has chosen a username; adding photos needs one.
  const HasChosenUsernameProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'hasChosenUsernameProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$hasChosenUsernameHash();

  @$internal
  @override
  $FutureProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<bool> create(Ref ref) {
    return hasChosenUsername(ref);
  }
}

String _$hasChosenUsernameHash() => r'b058185f5130314bc90374bb9d495af5879b1f37';

/// The signed-in user's submissions for one place, newest first.

@ProviderFor(myPlacePhotos)
const myPlacePhotosProvider = MyPlacePhotosFamily._();

/// The signed-in user's submissions for one place, newest first.

final class MyPlacePhotosProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<PhotoSubmission>>,
          List<PhotoSubmission>,
          FutureOr<List<PhotoSubmission>>
        >
    with
        $FutureModifier<List<PhotoSubmission>>,
        $FutureProvider<List<PhotoSubmission>> {
  /// The signed-in user's submissions for one place, newest first.
  const MyPlacePhotosProvider._({
    required MyPlacePhotosFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'myPlacePhotosProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$myPlacePhotosHash();

  @override
  String toString() {
    return r'myPlacePhotosProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<PhotoSubmission>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<PhotoSubmission>> create(Ref ref) {
    final argument = this.argument as String;
    return myPlacePhotos(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is MyPlacePhotosProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$myPlacePhotosHash() => r'decb068a1f51ba3fca274c03dafa3d650dfca477';

/// The signed-in user's submissions for one place, newest first.

final class MyPlacePhotosFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<PhotoSubmission>>, String> {
  const MyPlacePhotosFamily._()
    : super(
        retry: null,
        name: r'myPlacePhotosProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// The signed-in user's submissions for one place, newest first.

  MyPlacePhotosProvider call(String placeId) =>
      MyPlacePhotosProvider._(argument: placeId, from: this);

  @override
  String toString() => r'myPlacePhotosProvider';
}

/// A link to a pending submission's thumbnail (null if it can't be made).

@ProviderFor(pendingThumbnailUrl)
const pendingThumbnailUrlProvider = PendingThumbnailUrlFamily._();

/// A link to a pending submission's thumbnail (null if it can't be made).

final class PendingThumbnailUrlProvider
    extends $FunctionalProvider<AsyncValue<String?>, String?, FutureOr<String?>>
    with $FutureModifier<String?>, $FutureProvider<String?> {
  /// A link to a pending submission's thumbnail (null if it can't be made).
  const PendingThumbnailUrlProvider._({
    required PendingThumbnailUrlFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'pendingThumbnailUrlProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$pendingThumbnailUrlHash();

  @override
  String toString() {
    return r'pendingThumbnailUrlProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<String?> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<String?> create(Ref ref) {
    final argument = this.argument as String;
    return pendingThumbnailUrl(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is PendingThumbnailUrlProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$pendingThumbnailUrlHash() =>
    r'b88c77d821da475249e412c9626e4de547e5acad';

/// A link to a pending submission's thumbnail (null if it can't be made).

final class PendingThumbnailUrlFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<String?>, String> {
  const PendingThumbnailUrlFamily._()
    : super(
        retry: null,
        name: r'pendingThumbnailUrlProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// A link to a pending submission's thumbnail (null if it can't be made).

  PendingThumbnailUrlProvider call(String thumbPath) =>
      PendingThumbnailUrlProvider._(argument: thumbPath, from: this);

  @override
  String toString() => r'pendingThumbnailUrlProvider';
}

/// Every submission the user has sent, across all places (My photos).

@ProviderFor(myPhotos)
const myPhotosProvider = MyPhotosProvider._();

/// Every submission the user has sent, across all places (My photos).

final class MyPhotosProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<PhotoSubmission>>,
          List<PhotoSubmission>,
          FutureOr<List<PhotoSubmission>>
        >
    with
        $FutureModifier<List<PhotoSubmission>>,
        $FutureProvider<List<PhotoSubmission>> {
  /// Every submission the user has sent, across all places (My photos).
  const MyPhotosProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'myPhotosProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$myPhotosHash();

  @$internal
  @override
  $FutureProviderElement<List<PhotoSubmission>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<PhotoSubmission>> create(Ref ref) {
    return myPhotos(ref);
  }
}

String _$myPhotosHash() => r'fcd335c9d926fc83cfb240f750f2bd454df60181';

/// How many reviewed photos the user has not looked at (the blue dot).
/// A failed check means no dot.

@ProviderFor(unseenPhotoCount)
const unseenPhotoCountProvider = UnseenPhotoCountProvider._();

/// How many reviewed photos the user has not looked at (the blue dot).
/// A failed check means no dot.

final class UnseenPhotoCountProvider
    extends $FunctionalProvider<AsyncValue<int>, int, FutureOr<int>>
    with $FutureModifier<int>, $FutureProvider<int> {
  /// How many reviewed photos the user has not looked at (the blue dot).
  /// A failed check means no dot.
  const UnseenPhotoCountProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'unseenPhotoCountProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$unseenPhotoCountHash();

  @$internal
  @override
  $FutureProviderElement<int> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<int> create(Ref ref) {
    return unseenPhotoCount(ref);
  }
}

String _$unseenPhotoCountHash() => r'710368103cb79c7e97ccfcf5415d16fcd8afcc23';

/// The user's own username, for "Photo by @username" lines. Null while
/// loading or if it can't be read.

@ProviderFor(myPhotoHandle)
const myPhotoHandleProvider = MyPhotoHandleProvider._();

/// The user's own username, for "Photo by @username" lines. Null while
/// loading or if it can't be read.

final class MyPhotoHandleProvider
    extends $FunctionalProvider<AsyncValue<String?>, String?, FutureOr<String?>>
    with $FutureModifier<String?>, $FutureProvider<String?> {
  /// The user's own username, for "Photo by @username" lines. Null while
  /// loading or if it can't be read.
  const MyPhotoHandleProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'myPhotoHandleProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$myPhotoHandleHash();

  @$internal
  @override
  $FutureProviderElement<String?> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<String?> create(Ref ref) {
    return myPhotoHandle(ref);
  }
}

String _$myPhotoHandleHash() => r'e08b8b7ecd967bff9474aac61c14c0b37145d872';
