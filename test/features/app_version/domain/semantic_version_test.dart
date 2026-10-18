import 'package:flutter_test/flutter_test.dart';
import 'package:kaunti47_v2/src/features/app_version/domain/semantic_version.dart';

void main() {
  group('SemanticVersion', () {
    test('parses and compares numeric components', () {
      final current = SemanticVersion.tryParse('1.9.12')!;
      final next = SemanticVersion.tryParse('1.10.0')!;

      expect(next.compareTo(current), greaterThan(0));
      expect(current.toString(), '1.9.12');
    });

    test('rejects build metadata, prereleases and malformed versions', () {
      expect(SemanticVersion.tryParse('1.2.3+4'), isNull);
      expect(SemanticVersion.tryParse('1.2.3-beta'), isNull);
      expect(SemanticVersion.tryParse('01.2.3'), isNull);
      expect(SemanticVersion.tryParse('1.2'), isNull);
    });
  });
}
