import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/app_shimmer.dart';
import '../../../design/app_colors.dart';
import '../../../design/app_text_styles.dart';
import '../application/public_trip_providers.dart';
import '../application/public_trip_review_controller.dart';
import '../application/public_trip_review_state.dart';
import '../domain/public_trip_owner_view.dart';
import 'public_trip_route_preview.dart';
import 'public_trip_widgets.dart';

/// Step two: the sanitized preview the server built, the terms, and Submit.
class PublicTripPreviewBody extends ConsumerWidget {
  const PublicTripPreviewBody({
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
    final view = state.candidate!;
    final isLive = ref.watch(myPublicTripProvider(journeyId)).value?.isLive;
    final submitting = state.stage == PublicTripReviewStage.submitting;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
      children: [
        Text(view.title, style: AppTextStyles.detailTitle),
        const SizedBox(height: 4),
        const Text(
          'This is exactly what other people will see.',
          style: AppTextStyles.bodyMuted,
        ),
        const SizedBox(height: 14),
        PublicTripRoutePreview(lines: view.routeLines, moments: view.moments),
        const SizedBox(height: 10),
        const _Legend(),
        PublicTripNote(
          'The first ${view.startTrimMeters} m and last ${view.endTrimMeters} m are hidden, so the route starts and ends a little way in.',
        ),
        const PublicTripSectionTitle('What is shown'),
        _Facts(view: view),
        if (view.excludedMomentCount > 0 || view.excludedPhotoCount > 0)
          PublicTripNote(_excludedText(view)),
        _Photos(view: view, onCheck: controller.refreshPhotos),
        const PublicTripSectionTitle('Before you submit'),
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          value: state.consent,
          onChanged: submitting
              ? null
              : (value) => controller.setConsent(value ?? false),
          title: const Text(
            'I have the right to share this, and I understand other people may copy what I publish.',
            style: AppTextStyles.listItemSubtitle,
          ),
        ),
        if (isLive ?? false)
          const PublicTripNote(
            'Your current version stays live until this change is approved.',
          ),
        if (state.error != null) PublicTripNote(state.error!, isError: true),
        const SizedBox(height: 16),
        PublicTripPrimaryButton(
          label: 'Submit for review',
          busy: submitting,
          onPressed: state.canSubmit ? controller.submit : null,
        ),
        const SizedBox(height: 8),
        Center(
          child: TextButton(
            onPressed: submitting ? null : controller.backToChoices,
            child: const Text('Back to choices'),
          ),
        ),
      ],
    );
  }

  static String _excludedText(PublicTripOwnerView view) {
    final parts = [
      if (view.excludedMomentCount > 0)
        '${view.excludedMomentCount} moment${view.excludedMomentCount == 1 ? '' : 's'}',
      if (view.excludedPhotoCount > 0)
        '${view.excludedPhotoCount} photo${view.excludedPhotoCount == 1 ? '' : 's'}',
    ];
    return '${parts.join(' and ')} left out because '
        '${parts.length == 1 && view.excludedMomentCount + view.excludedPhotoCount == 1 ? 'it was' : 'they were'} '
        'inside a hidden part of the route.';
  }
}

class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) {
    Widget item(Color color, String label) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(radius: 5, backgroundColor: color),
        const SizedBox(width: 6),
        Text(label, style: AppTextStyles.bodySmall),
      ],
    );
    return Wrap(
      spacing: 16,
      runSpacing: 6,
      children: [
        item(AppColors.legendHome, 'Public start'),
        item(AppColors.danger, 'Public end'),
        item(AppColors.pendingFill, 'Moment'),
      ],
    );
  }
}

class _Facts extends StatelessWidget {
  const _Facts({required this.view});

  final PublicTripOwnerView view;

  @override
  Widget build(BuildContext context) {
    final date = view.tripDate;
    final km = (view.distanceMeters / 1000).toStringAsFixed(1);
    final rows = <(String, String)>[
      ('Date', date == null ? '' : publicTripDateLabel(date)),
      ('Distance', '$km km'),
      ('Counties', view.counties.map((c) => c.name).join(', ')),
      ('Moments', '${view.moments.length}'),
      ('Photos', '${view.photoCount}'),
    ];
    return Column(
      children: [
        for (final (label, value) in rows)
          if (value.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 96,
                    child: Text(label, style: AppTextStyles.bodySmall),
                  ),
                  Expanded(
                    child: Text(value, style: AppTextStyles.listItemTitle),
                  ),
                ],
              ),
            ),
      ],
    );
  }
}

/// Photos are copied in the background, so the preview may open before
/// they are ready: say so, and let the owner look again.
class _Photos extends StatelessWidget {
  const _Photos({required this.view, required this.onCheck});

  final PublicTripOwnerView view;
  final VoidCallback onCheck;

  @override
  Widget build(BuildContext context) {
    if (view.photosFailed > 0) {
      return const PublicTripNote(
        "A photo couldn't be prepared. Go back and take it off, then preview again.",
        isError: true,
      );
    }
    if (view.photosPending > 0) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),
          const AppShimmer(child: AppSkeleton(height: 14, width: 180)),
          const SizedBox(height: 6),
          const Text(
            'Photos are still being prepared.',
            style: AppTextStyles.bodySmall,
          ),
          TextButton(onPressed: onCheck, child: const Text('Check again')),
        ],
      );
    }
    return const SizedBox.shrink();
  }
}
