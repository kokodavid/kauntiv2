// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'plan_offline_copy.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(planOfflineMap)
const planOfflineMapProvider = PlanOfflineMapProvider._();

final class PlanOfflineMapProvider
    extends $FunctionalProvider<PlanOfflineMap, PlanOfflineMap, PlanOfflineMap>
    with $Provider<PlanOfflineMap> {
  const PlanOfflineMapProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'planOfflineMapProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$planOfflineMapHash();

  @$internal
  @override
  $ProviderElement<PlanOfflineMap> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  PlanOfflineMap create(Ref ref) {
    return planOfflineMap(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PlanOfflineMap value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PlanOfflineMap>(value),
    );
  }
}

String _$planOfflineMapHash() => r'244f7cf6a950024bbf79ff8e485d25152651af33';

@ProviderFor(planOfflineStore)
const planOfflineStoreProvider = PlanOfflineStoreProvider._();

final class PlanOfflineStoreProvider
    extends
        $FunctionalProvider<
          PlanOfflineStore,
          PlanOfflineStore,
          PlanOfflineStore
        >
    with $Provider<PlanOfflineStore> {
  const PlanOfflineStoreProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'planOfflineStoreProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$planOfflineStoreHash();

  @$internal
  @override
  $ProviderElement<PlanOfflineStore> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  PlanOfflineStore create(Ref ref) {
    return planOfflineStore(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PlanOfflineStore value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PlanOfflineStore>(value),
    );
  }
}

String _$planOfflineStoreHash() => r'32bdb6bde95cc166bd4ce658214e44e251139773';

@ProviderFor(planOfflineImages)
const planOfflineImagesProvider = PlanOfflineImagesProvider._();

final class PlanOfflineImagesProvider
    extends
        $FunctionalProvider<
          PlanOfflineImages,
          PlanOfflineImages,
          PlanOfflineImages
        >
    with $Provider<PlanOfflineImages> {
  const PlanOfflineImagesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'planOfflineImagesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$planOfflineImagesHash();

  @$internal
  @override
  $ProviderElement<PlanOfflineImages> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  PlanOfflineImages create(Ref ref) {
    return planOfflineImages(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PlanOfflineImages value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PlanOfflineImages>(value),
    );
  }
}

String _$planOfflineImagesHash() => r'05240ad3b4cd0931f51383805d976b18641be268';

/// A plan's offline copy (Pro): the map around its stops and its place
/// pictures, saved on this phone. Reading a plan you've opened before
/// already works offline for everyone; this adds the map and pictures.

@ProviderFor(PlanOfflineCopy)
const planOfflineCopyProvider = PlanOfflineCopyFamily._();

/// A plan's offline copy (Pro): the map around its stops and its place
/// pictures, saved on this phone. Reading a plan you've opened before
/// already works offline for everyone; this adds the map and pictures.
final class PlanOfflineCopyProvider
    extends $AsyncNotifierProvider<PlanOfflineCopy, PlanOfflineState> {
  /// A plan's offline copy (Pro): the map around its stops and its place
  /// pictures, saved on this phone. Reading a plan you've opened before
  /// already works offline for everyone; this adds the map and pictures.
  const PlanOfflineCopyProvider._({
    required PlanOfflineCopyFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'planOfflineCopyProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$planOfflineCopyHash();

  @override
  String toString() {
    return r'planOfflineCopyProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  PlanOfflineCopy create() => PlanOfflineCopy();

  @override
  bool operator ==(Object other) {
    return other is PlanOfflineCopyProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$planOfflineCopyHash() => r'f7e3a40642a4e63f3e3e31b65efafad54d6f8037';

/// A plan's offline copy (Pro): the map around its stops and its place
/// pictures, saved on this phone. Reading a plan you've opened before
/// already works offline for everyone; this adds the map and pictures.

final class PlanOfflineCopyFamily extends $Family
    with
        $ClassFamilyOverride<
          PlanOfflineCopy,
          AsyncValue<PlanOfflineState>,
          PlanOfflineState,
          FutureOr<PlanOfflineState>,
          String
        > {
  const PlanOfflineCopyFamily._()
    : super(
        retry: null,
        name: r'planOfflineCopyProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// A plan's offline copy (Pro): the map around its stops and its place
  /// pictures, saved on this phone. Reading a plan you've opened before
  /// already works offline for everyone; this adds the map and pictures.

  PlanOfflineCopyProvider call(String planId) =>
      PlanOfflineCopyProvider._(argument: planId, from: this);

  @override
  String toString() => r'planOfflineCopyProvider';
}

/// A plan's offline copy (Pro): the map around its stops and its place
/// pictures, saved on this phone. Reading a plan you've opened before
/// already works offline for everyone; this adds the map and pictures.

abstract class _$PlanOfflineCopy extends $AsyncNotifier<PlanOfflineState> {
  late final _$args = ref.$arg as String;
  String get planId => _$args;

  FutureOr<PlanOfflineState> build(String planId);
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build(_$args);
    final ref =
        this.ref as $Ref<AsyncValue<PlanOfflineState>, PlanOfflineState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<PlanOfflineState>, PlanOfflineState>,
              AsyncValue<PlanOfflineState>,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
