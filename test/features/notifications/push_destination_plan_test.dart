import 'package:flutter_test/flutter_test.dart';
import 'package:kaunti47_v2/src/features/notifications/domain/push_destination.dart';

void main() {
  test('plan and trips destinations come through, with a plan id', () {
    final plan = PushDestination.fromData({
      'dest_kind': 'plan',
      'dest_id': 'abc',
    });
    expect(plan.kind, PushDestinationKind.plan);
    expect(plan.id, 'abc');
    expect(
      PushDestination.fromData({'dest_kind': 'trips'}).kind,
      PushDestinationKind.trips,
    );
  });

  test('an unknown kind still opens Home', () {
    expect(
      PushDestination.fromData({'dest_kind': 'brand_new'}).kind,
      PushDestinationKind.home,
    );
  });
}
