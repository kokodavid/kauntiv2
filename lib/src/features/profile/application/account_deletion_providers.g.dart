// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'account_deletion_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(accountDeletionRepository)
const accountDeletionRepositoryProvider = AccountDeletionRepositoryProvider._();

final class AccountDeletionRepositoryProvider
    extends
        $FunctionalProvider<
          AccountDeletionRepository?,
          AccountDeletionRepository?,
          AccountDeletionRepository?
        >
    with $Provider<AccountDeletionRepository?> {
  const AccountDeletionRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'accountDeletionRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$accountDeletionRepositoryHash();

  @$internal
  @override
  $ProviderElement<AccountDeletionRepository?> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  AccountDeletionRepository? create(Ref ref) {
    return accountDeletionRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AccountDeletionRepository? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AccountDeletionRepository?>(value),
    );
  }
}

String _$accountDeletionRepositoryHash() =>
    r'2f9c6e3b8a5d1047f9c6e3b8a5d1047f9c6e3b8';
