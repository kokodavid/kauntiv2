import 'package:flutter_test/flutter_test.dart';
import 'package:kaunti47_v2/src/features/app_version/domain/update_notes.dart';

void main() {
  test('strips bullet markers and blank lines', () {
    expect(
      parseUpdateNotes('- Faster map\n* Fixed sign-in\n\n• New badges\nPlain'),
      ['Faster map', 'Fixed sign-in', 'New badges', 'Plain'],
    );
  });

  test('null and empty notes give no items', () {
    expect(parseUpdateNotes(null), isEmpty);
    expect(parseUpdateNotes('  \n '), isEmpty);
  });
}
