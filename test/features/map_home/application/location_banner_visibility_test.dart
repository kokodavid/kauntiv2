import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaunti47_v2/src/features/detection/domain/detection_status.dart';
import 'package:kaunti47_v2/src/features/map_home/application/location_banner_visibility.dart';
import 'package:kaunti47_v2/src/features/map_home/presentation/map_home_location_banner.dart';

void main() {
  test('the banner is visible at launch and hidden after dismiss', () {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    expect(c.read(locationBannerVisibleProvider), isTrue);
    c.read(locationBannerVisibleProvider.notifier).dismiss();
    expect(c.read(locationBannerVisibleProvider), isFalse);
  });

  test('it shows only for a problem and only while still visible', () {
    expect(
      MapHomeLocationBanner.shows(DetectionReason.none, visible: true),
      isFalse,
    );
    expect(
      MapHomeLocationBanner.shows(
        DetectionReason.backgroundMissing,
        visible: true,
      ),
      isTrue,
    );
    expect(
      MapHomeLocationBanner.shows(DetectionReason.noPermission, visible: false),
      isFalse,
    );
  });
}
