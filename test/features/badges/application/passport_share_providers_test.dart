import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaunti47_v2/src/features/badges/application/passport_share_providers.dart';
import 'package:kaunti47_v2/src/features/badges/data/passport_share_flag_repository.dart';

class _FakeFlagRepository implements PassportShareFlagRepository {
  _FakeFlagRepository({this.live, this.last});

  /// Null makes the live read fail.
  final bool? live;
  final bool? last;

  @override
  Future<bool> isEnabled() async {
    final value = live;
    if (value == null) throw StateError('offline');
    return value;
  }

  @override
  Future<bool?> lastKnown() async => last;
}

Future<bool> _read(PassportShareFlagRepository? repository) {
  final container = ProviderContainer(
    overrides: [
      passportShareFlagRepositoryProvider.overrideWithValue(repository),
    ],
  );
  addTearDown(container.dispose);
  return container.read(passportShareFlagProvider.future);
}

void main() {
  test('uses the live switch when it can be read', () async {
    expect(await _read(_FakeFlagRepository(live: true, last: false)), isTrue);
    expect(await _read(_FakeFlagRepository(live: false, last: true)), isFalse);
  });

  test('falls back to the last value seen when the read fails', () async {
    expect(await _read(_FakeFlagRepository(last: true)), isTrue);
  });

  test('is off with no read and nothing remembered', () async {
    expect(await _read(_FakeFlagRepository()), isFalse);
  });

  test('is off without Supabase', () async {
    expect(await _read(null), isFalse);
  });
}
