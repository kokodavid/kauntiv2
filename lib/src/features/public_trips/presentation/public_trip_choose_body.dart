import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../design/app_colors.dart';
import '../../../design/app_text_styles.dart';
import '../application/public_trip_review_controller.dart';
import '../application/public_trip_review_state.dart';
import '../domain/public_trip_share_preferences.dart';
import 'public_trip_moments_section.dart';
import 'public_trip_photos_section.dart';
import 'public_trip_widgets.dart';

/// Step one: name the trip, say how much of each end to hide, and pick the
/// moments and photos to show.
class PublicTripChooseBody extends ConsumerWidget {
  const PublicTripChooseBody({
    super.key,
    required this.journeyId,
    required this.state,
    required this.onOpenDefaults,
  });

  final String journeyId;
  final PublicTripReviewState state;
  final VoidCallback? onOpenDefaults;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(
      publicTripReviewControllerProvider(journeyId).notifier,
    );
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
      children: [
        const Text(
          'Choose what other people can see. A moderator checks it before it goes live.',
          style: AppTextStyles.bodyMuted,
        ),
        const PublicTripSectionTitle('Title'),
        TextFormField(
          initialValue: state.title,
          maxLength: 80,
          onChanged: controller.setTitle,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(
            hintText: 'Name this trip',
            filled: true,
            fillColor: AppColors.secondaryFill,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const PublicTripSectionTitle('Hidden at each end'),
        Wrap(
          spacing: 8,
          children: [
            for (final meters in PublicTripSharePreferences.trimChoices)
              ChoiceChip(
                label: Text(
                  meters >= 1000 ? '${meters ~/ 1000} km' : '$meters m',
                ),
                selected: state.trimMeters == meters,
                onSelected: (_) => controller.setTrim(meters),
              ),
          ],
        ),
        const PublicTripNote(
          'The start and end of your route are cut off so nobody can tell where you live, park or work.',
        ),
        PublicTripMomentsSection(journeyId: journeyId, state: state),
        PublicTripPhotosSection(journeyId: journeyId, state: state),
        const SizedBox(height: 14),
        Row(
          children: [
            const Expanded(
              child: Text(
                'Starting from your share defaults',
                style: AppTextStyles.bodySmall,
              ),
            ),
            if (onOpenDefaults != null)
              TextButton(onPressed: onOpenDefaults, child: const Text('Edit')),
          ],
        ),
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          value: state.saveAsDefault,
          onChanged: (value) => controller.setSaveAsDefault(value ?? false),
          title: const Text(
            'Use these choices as my defaults',
            style: AppTextStyles.listItemSubtitle,
          ),
        ),
        if (state.error != null) PublicTripNote(state.error!, isError: true),
        const SizedBox(height: 16),
        PublicTripPrimaryButton(
          label: 'Preview what will be public',
          onPressed: state.canPrepare ? controller.prepare : null,
        ),
      ],
    );
  }
}
