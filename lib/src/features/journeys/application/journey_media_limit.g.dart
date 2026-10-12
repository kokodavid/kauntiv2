// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'journey_media_limit.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The signed-in account's per-Trip photo limit, read live from the server.
/// Null when it can't be read (offline): the app then doesn't pre-trim, and
/// the server's own check still applies when photos upload.

@ProviderFor(journeyMediaLimit)
const journeyMediaLimitProvider = JourneyMediaLimitProvider._();

/// The signed-in account's per-Trip photo limit, read live from the server.
/// Null when it can't be read (offline): the app then doesn't pre-trim, and
/// the server's own check still applies when photos upload.

final class JourneyMediaLimitProvider
    extends
        $FunctionalProvider<
          AsyncValue<JourneyMediaLimit?>,
          JourneyMediaLimit?,
          FutureOr<JourneyMediaLimit?>
        >
    with
        $FutureModifier<JourneyMediaLimit?>,
        $FutureProvider<JourneyMediaLimit?> {
  /// The signed-in account's per-Trip photo limit, read live from the server.
  /// Null when it can't be read (offline): the app then doesn't pre-trim, and
  /// the server's own check still applies when photos upload.
  const JourneyMediaLimitProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'journeyMediaLimitProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$journeyMediaLimitHash();

  @$internal
  @override
  $FutureProviderElement<JourneyMediaLimit?> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<JourneyMediaLimit?> create(Ref ref) {
    return journeyMediaLimit(ref);
  }
}

String _$journeyMediaLimitHash() => r'1aaab68130344ab8dc80a268113d42de4dfd32c5';
