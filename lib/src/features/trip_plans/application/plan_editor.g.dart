// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'plan_editor.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(planEditor)
const planEditorProvider = PlanEditorProvider._();

final class PlanEditorProvider
    extends $FunctionalProvider<PlanEditor, PlanEditor, PlanEditor>
    with $Provider<PlanEditor> {
  const PlanEditorProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'planEditorProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$planEditorHash();

  @$internal
  @override
  $ProviderElement<PlanEditor> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  PlanEditor create(Ref ref) {
    return planEditor(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PlanEditor value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PlanEditor>(value),
    );
  }
}

String _$planEditorHash() => r'5360d31e51d519ff2ec1be8d851682b10a968cca';
