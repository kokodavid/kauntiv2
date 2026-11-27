import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../design/app_text_styles.dart';
import '../../detection/application/detection_controller.dart';
import '../../detection/domain/detection_status.dart';
import '../application/location_banner_visibility.dart';
import 'map_home_location_copy.dart';

/// Takes the stat card's place at the top of Home while detection can't work
/// at full strength, and says what the app can't do and what to tap. Amber
/// for catch-up ("While using": counties are recorded only while the app is
/// open), red when nothing is being tracked (no permission, or location off
/// for the phone). Nothing shows when detection is live.
///
/// It stays for [LocationBannerVisibility.showFor] after it first appears in
/// a launch, then hides itself and the stat card returns; it appears again on
/// the next launch while the problem remains.
class MapHomeLocationBanner extends ConsumerStatefulWidget {
  const MapHomeLocationBanner({super.key, required this.reason});

  final DetectionReason reason;

  /// Whether the banner has anything to say for [reason], and hasn't yet
  /// had its turn this launch ([visible]).
  static bool shows(DetectionReason reason, {required bool visible}) =>
      visible && reason != DetectionReason.none;

  @override
  ConsumerState<MapHomeLocationBanner> createState() =>
      _MapHomeLocationBannerState();
}

class _MapHomeLocationBannerState extends ConsumerState<MapHomeLocationBanner> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(LocationBannerVisibility.showFor, () {
      if (mounted) ref.read(locationBannerVisibleProvider.notifier).dismiss();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reason = widget.reason;
    final controller = ref.read(detectionControllerProvider.notifier);
    final copy = LocationStatusCopy.of(reason);
    return Semantics(
      container: true,
      label: '${copy.title}. ${copy.body}',
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: copy.background,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: copy.border, width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 1),
                  child: Icon(
                    Icons.location_off_outlined,
                    size: 22,
                    color: copy.accent,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        copy.title,
                        style: AppTextStyles.listItemTitle.copyWith(
                          fontSize: 14,
                          height: 1.3,
                          fontWeight: FontWeight.w700,
                          color: copy.ink,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        copy.body,
                        style: AppTextStyles.bodySmall.copyWith(
                          fontSize: 12.5,
                          height: 1.4,
                          fontWeight: FontWeight.w400,
                          color: copy.ink,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 36,
              child: ElevatedButton(
                onPressed: () => unawaited(
                  reason == DetectionReason.servicesOff
                      ? controller.turnOnLocation()
                      : controller.openLocationSettings(),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: copy.accent,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  copy.action,
                  style: AppTextStyles.listItemTitle.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
