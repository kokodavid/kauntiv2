import 'package:flutter_test/flutter_test.dart';
import 'package:kaunti47_v2/src/features/app_version/domain/app_update_policy.dart';
import 'package:kaunti47_v2/src/features/app_version/domain/semantic_version.dart';

void main() {
  test('accepts only HTTPS store links and parses server update flags', () {
    final policy = AppUpdatePolicy.fromJson({
      'latest_version': '2.0.0',
      'required_version': '2.0.0',
      'available': true,
      'required': true,
      'store_url': 'http://example.test/app',
      'release_notes': 'Important update',
    }, const SemanticVersion(1, 9, 2));

    expect(policy.available, isTrue);
    expect(policy.required, isTrue);
    expect(policy.storeUrl, isNull);
    expect(policy.latestVersion?.toString(), '2.0.0');
  });
}
