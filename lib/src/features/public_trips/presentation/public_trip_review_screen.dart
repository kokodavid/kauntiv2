import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/app_back_button.dart';
import '../../../core/widgets/app_shimmer.dart';
import '../../../design/app_colors.dart';
import '../../../design/app_text_styles.dart';
import '../application/public_trip_review_controller.dart';
import '../application/public_trip_review_state.dart';
import 'public_trip_choose_body.dart';
import 'public_trip_preview_body.dart';
import 'public_trip_submitted_body.dart';

/// Review and submit one trip as a public trip. Opened from the Share trip
/// sheet; [onOpenDefaults] opens the share-defaults screen (the app owns
/// navigation).
class PublicTripReviewScreen extends ConsumerWidget {
  const PublicTripReviewScreen({
    super.key,
    required this.journeyId,
    this.onOpenDefaults,
  });

  final String journeyId;
  final VoidCallback? onOpenDefaults;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(publicTripReviewControllerProvider(journeyId));
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        leadingWidth: 64,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16),
          child: Center(
            child: AppBackButton(
              onPressed: () => Navigator.of(context).maybePop(),
            ),
          ),
        ),
        title: const Text('Make trip public', style: AppTextStyles.detailNavTitle),
        centerTitle: true,
      ),
      body: SafeArea(
        child: async.when(
          loading: () => const _Skeleton(label: 'Loading your trip'),
          error: (_, _) => const Center(
            child: Padding(
              padding: EdgeInsets.all(28),
              child: Text(
                "Couldn't load this trip. Check your connection and try again.",
                style: AppTextStyles.bodyMuted,
                textAlign: TextAlign.center,
              ),
            ),
          ),
          data: (state) => switch (state.stage) {
            PublicTripReviewStage.choose => PublicTripChooseBody(
              journeyId: journeyId,
              state: state,
              onOpenDefaults: onOpenDefaults,
            ),
            PublicTripReviewStage.preparing => const _Skeleton(
              label: 'Preparing your preview',
            ),
            PublicTripReviewStage.preview ||
            PublicTripReviewStage.submitting => PublicTripPreviewBody(
              journeyId: journeyId,
              state: state,
            ),
            PublicTripReviewStage.submitted => PublicTripSubmittedBody(
              onDone: () => Navigator.of(context).maybePop(),
            ),
          },
        ),
      ),
    );
  }
}

/// A stable, map-shaped placeholder while the server prepares the preview.
/// The full private route is never drawn here.
class _Skeleton extends StatelessWidget {
  const _Skeleton({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppShimmer(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppSkeleton(height: 200, radius: 16),
                SizedBox(height: 18),
                AppSkeleton(height: 16, width: 220),
                SizedBox(height: 10),
                AppSkeleton(height: 12),
                SizedBox(height: 8),
                AppSkeleton(height: 12, width: 260),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Text(label, style: AppTextStyles.bodySmall.copyWith(color: AppColors.mutedForeground)),
        ],
      ),
    );
  }
}
