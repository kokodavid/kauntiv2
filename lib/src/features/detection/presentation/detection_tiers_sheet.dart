import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../design/app_colors.dart';
import '../../../design/app_text_styles.dart';
import '../application/detection_controller.dart';
import '../domain/detection_status.dart';

/// What each location choice gives, which one the phone is on, and how to
/// reach "All the time" on this platform. Opened from Home's location pill
/// and, once, after the first claimed county.
Future<void> showDetectionTiersSheet(
  BuildContext context, {
  bool afterFirstCounty = false,
}) {
  return showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    backgroundColor: AppColors.pageBackground,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
    ),
    showDragHandle: true,
    isScrollControlled: true,
    builder: (sheetContext) => ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.9,
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: DetectionTiersContent(
            afterFirstCounty: afterFirstCounty,
            onDone: () => Navigator.of(sheetContext).pop(),
          ),
        ),
      ),
    ),
  );
}

class DetectionTiersContent extends ConsumerWidget {
  const DetectionTiersContent({
    super.key,
    required this.onDone,
    this.afterFirstCounty = false,
  });

  final VoidCallback onDone;
  final bool afterFirstCounty;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(detectionControllerProvider.select((s) => s.status));
    final controller = ref.read(detectionControllerProvider.notifier);
    final ios = defaultTargetPlatform == TargetPlatform.iOS;
    final live = status.tier == DetectionTier.live;
    final servicesOff = status.reason == DetectionReason.servicesOff;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          afterFirstCounty ? 'Nice, your first county' : 'How Kaunti47 tracks',
          style: AppTextStyles.listItemTitle.copyWith(fontSize: 20),
        ),
        const SizedBox(height: 6),
        Text(
          afterFirstCounty
              ? 'Want the next ones caught even when the app is closed?'
              : 'Pick how much Kaunti47 can see. You can change it any time.',
          style: AppTextStyles.listItemTitle.copyWith(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.mutedForeground,
          ),
        ),
        const SizedBox(height: 14),
        _TierRow(
          title: 'Allow all the time',
          body: 'Counties are recorded as you cross, even with the app '
              'closed. Uses a little more battery.',
          current: live,
        ),
        _TierRow(
          title: 'While using',
          body: 'Counties are recorded when you open Kaunti47.',
          current: status.tier == DetectionTier.catchUp,
        ),
        _TierRow(
          title: 'Off',
          body: 'Nothing is recorded until location is back on.',
          current: status.tier == DetectionTier.off,
        ),
        if (!live) ...[
          const SizedBox(height: 6),
          Text(
            ios
                ? 'To get there: Settings > Kaunti47 > Location > Always.'
                : 'To get there: Settings > Apps > Kaunti47 > Permissions > '
                      'Location > Allow all the time.',
            style: AppTextStyles.listItemTitle.copyWith(
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.green,
                minimumSize: const Size.fromHeight(48),
              ),
              onPressed: () {
                onDone();
                unawaited(
                  servicesOff
                      ? controller.turnOnLocation()
                      : controller.askForAlways(),
                );
              },
              child: Text(servicesOff ? 'Turn on location' : 'Allow all the time'),
            ),
          ),
        ],
        const SizedBox(height: 4),
        Center(
          child: TextButton(
            onPressed: onDone,
            child: Text(live ? 'Done' : 'Not now'),
          ),
        ),
      ],
    );
  }
}

class _TierRow extends StatelessWidget {
  const _TierRow({
    required this.title,
    required this.body,
    required this.current,
  });

  final String title;
  final String body;
  final bool current;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: current ? AppColors.green : AppColors.cardBorder,
          width: current ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: AppTextStyles.listItemTitle.copyWith(fontSize: 15),
                ),
              ),
              if (current)
                Text(
                  "You're here",
                  style: AppTextStyles.listItemTitle.copyWith(
                    fontSize: 12,
                    color: AppColors.green,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            body,
            style: AppTextStyles.listItemTitle.copyWith(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.mutedForeground,
            ),
          ),
        ],
      ),
    );
  }
}
