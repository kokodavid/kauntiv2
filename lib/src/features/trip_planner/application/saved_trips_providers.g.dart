// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'saved_trips_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Null when this build has no Supabase.

@ProviderFor(savedTripsRepository)
const savedTripsRepositoryProvider = SavedTripsRepositoryProvider._();

/// Null when this build has no Supabase.

final class SavedTripsRepositoryProvider
    extends
        $FunctionalProvider<
          SavedTripsRepository?,
          SavedTripsRepository?,
          SavedTripsRepository?
        >
    with $Provider<SavedTripsRepository?> {
  /// Null when this build has no Supabase.
  const SavedTripsRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'savedTripsRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$savedTripsRepositoryHash();

  @$internal
  @override
  $ProviderElement<SavedTripsRepository?> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  SavedTripsRepository? create(Ref ref) {
    return savedTripsRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SavedTripsRepository? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SavedTripsRepository?>(value),
    );
  }
}

String _$savedTripsRepositoryHash() =>
    r'd87869ce09971da6b8e758cb73eb3a81641e8e43';

/// The user's saved plans to a place, newest first. Empty when they cannot
/// be read: the list then simply does not show.

@ProviderFor(savedTripsForPlace)
const savedTripsForPlaceProvider = SavedTripsForPlaceFamily._();

/// The user's saved plans to a place, newest first. Empty when they cannot
/// be read: the list then simply does not show.

final class SavedTripsForPlaceProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<SavedTrip>>,
          List<SavedTrip>,
          FutureOr<List<SavedTrip>>
        >
    with $FutureModifier<List<SavedTrip>>, $FutureProvider<List<SavedTrip>> {
  /// The user's saved plans to a place, newest first. Empty when they cannot
  /// be read: the list then simply does not show.
  const SavedTripsForPlaceProvider._({
    required SavedTripsForPlaceFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'savedTripsForPlaceProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$savedTripsForPlaceHash();

  @override
  String toString() {
    return r'savedTripsForPlaceProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<SavedTrip>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<SavedTrip>> create(Ref ref) {
    final argument = this.argument as String;
    return savedTripsForPlace(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is SavedTripsForPlaceProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$savedTripsForPlaceHash() =>
    r'0858619233c32d4b3fc6b43eaca398db8dd2b339';

/// The user's saved plans to a place, newest first. Empty when they cannot
/// be read: the list then simply does not show.

final class SavedTripsForPlaceFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<SavedTrip>>, String> {
  const SavedTripsForPlaceFamily._()
    : super(
        retry: null,
        name: r'savedTripsForPlaceProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// The user's saved plans to a place, newest first. Empty when they cannot
  /// be read: the list then simply does not show.

  SavedTripsForPlaceProvider call(String placeId) =>
      SavedTripsForPlaceProvider._(argument: placeId, from: this);

  @override
  String toString() => r'savedTripsForPlaceProvider';
}

/// All the user's saved plans, newest first, for Home and the saved plans
/// screen. Empty when they cannot be read.

@ProviderFor(savedTripsAll)
const savedTripsAllProvider = SavedTripsAllProvider._();

/// All the user's saved plans, newest first, for Home and the saved plans
/// screen. Empty when they cannot be read.

final class SavedTripsAllProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<SavedTrip>>,
          List<SavedTrip>,
          FutureOr<List<SavedTrip>>
        >
    with $FutureModifier<List<SavedTrip>>, $FutureProvider<List<SavedTrip>> {
  /// All the user's saved plans, newest first, for Home and the saved plans
  /// screen. Empty when they cannot be read.
  const SavedTripsAllProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'savedTripsAllProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$savedTripsAllHash();

  @$internal
  @override
  $FutureProviderElement<List<SavedTrip>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<SavedTrip>> create(Ref ref) {
    return savedTripsAll(ref);
  }
}

String _$savedTripsAllHash() => r'8aba7abc3d1a02aa8366f5d583f3bf4fabe60545';
