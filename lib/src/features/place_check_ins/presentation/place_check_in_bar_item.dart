import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/app_floating_toast.dart';
import '../../../core/widgets/place_detail_bar_button.dart';
import '../../../design/app_colors.dart';
import '../application/place_check_in_providers.dart';
import '../domain/check_in_outcome.dart';
import 'check_in_messages.dart';
import 'check_in_view.dart';

/// "I'm here" as one item of Place Detail's floating action bar. Reuses
/// the same state machine the old full-width check-in card used
/// ([CheckInView.of]); what was a line of text under that card now
/// surfaces as a floating toast, since the bar has no room for a second
/// line. Renders nothing while check-ins are off for this place.
class PlaceCheckInBarItem extends ConsumerWidget {
  const PlaceCheckInBarItem({
    super.key,
    required this.placeId,
    required this.placeName,
  });

  final String placeId;
  final String placeName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(placeCheckInStatusProvider(placeId)).value;
    if (status == null || !status.enabled) return const SizedBox.shrink();
    final controller = ref.watch(placeCheckInControllerProvider(placeId));

    // One message per outcome, as a toast instead of a permanent line on
    // the page.
    ref.listen(placeCheckInControllerProvider(placeId), (previous, next) {
      if (next.hasError) {
        showAppToast(
          context,
          variant: AppToastVariant.error,
          title: "Couldn't check in",
          message: checkInErrorShort,
        );
        return;
      }
      final outcome = next.value;
      if (outcome == null) return;
      if (previous != null && previous.value == outcome) return;
      showAppToast(
        context,
        variant: !outcome.counted
            ? AppToastVariant.warning
            : outcome.already
            ? AppToastVariant.neutral
            : AppToastVariant.success,
        title: checkInMessage(outcome, placeName),
      );
    });

    final view = CheckInView.of(
      status: status,
      outcome: controller.value,
      placeName: placeName,
      busy: controller.isLoading,
      failed: controller.hasError,
    );
    final failure = controller.value?.failure;
    final label =
        view.action ??
        switch (failure) {
          CheckInFailure.dailyLimit => "Today's limit",
          CheckInFailure.placeUnavailable => 'Unavailable',
          CheckInFailure.paused => 'Paused',
          _ => 'Checked in',
        };
    return PlaceDetailBarButton(
      icon: switch (view.icon) {
        CheckInIcon.pin => Icons.place_outlined,
        CheckInIcon.check => Icons.check_rounded,
        CheckInIcon.signal => Icons.signal_cellular_alt_rounded,
        CheckInIcon.clock => Icons.schedule_rounded,
        CheckInIcon.locationOff => Icons.location_off_outlined,
      },
      label: label,
      busy: view.busy,
      tone: view.tinted ? AppColors.accentDark : null,
      onPressed: view.action == null
          ? null
          : () => ref
                .read(placeCheckInControllerProvider(placeId).notifier)
                .checkIn(),
    );
  }
}
