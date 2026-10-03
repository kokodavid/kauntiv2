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
    r'aaf45c8fecdc348e7de78782dca63b6d98f29da1';
