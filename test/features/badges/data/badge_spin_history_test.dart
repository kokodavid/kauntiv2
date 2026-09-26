import 'package:flutter_test/flutter_test.dart';
import 'package:kaunti47_v2/src/features/badges/data/badge_spin_history.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('each badge spins once per account', () async {
    const history = BadgeSpinHistory();
    expect(await history.claimFirstSpin('alice', 47), isTrue);
    expect(await history.claimFirstSpin('alice', 47), isFalse);
    expect(await history.claimFirstSpin('alice', 22), isTrue);
    // Another account on the phone gets its own first spins.
    expect(await history.claimFirstSpin('bob', 47), isTrue);
  });
}
