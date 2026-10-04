import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../design/app_colors.dart';
import '../../../design/app_text_styles.dart';
import '../application/public_trip_review_controller.dart';
import '../application/public_trip_review_state.dart';
import 'public_trip_widgets.dart';

/// One switch per moment of the trip. Kinds that say more about the person
/// than the place carry a light privacy hint.
class PublicTripMomentsSection extends ConsumerWidget {
  const PublicTripMomentsSection({
    super.key,
    required this.journeyId,
    required this.state,
  });

  final String journeyId;
  final PublicTripReviewState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(
      publicTripReviewControllerProvider(journeyId).notifier,
    );
    final options = state.momentOptions;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PublicTripSectionTitle(
          'Moments',
          trailing: '${state.selectedMoments.length} of ${options.length}',
        ),
        if (options.isEmpty)
          const Text(
            'This trip has no moments to show.',
            style: AppTextStyles.bodySmall,
          ),
        for (final option in options)
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            activeTrackColor: AppColors.accent,
            value: state.selectedMoments.contains(option.key),
            onChanged: (_) => controller.toggleMoment(option.key),
            title: Text(option.kind.label, style: AppTextStyles.listItemTitle),
            subtitle: Text(
              [
                if (option.detail.isNotEmpty) option.detail,
                if (option.kind.hint != null) option.kind.hint!,
              ].join(' · '),
              style: AppTextStyles.listItemSubtitle,
            ),
          ),
      ],
    );
  }
}
