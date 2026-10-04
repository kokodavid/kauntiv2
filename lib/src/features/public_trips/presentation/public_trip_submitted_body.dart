import 'package:flutter/material.dart';

import '../../../design/app_colors.dart';
import '../../../design/app_text_styles.dart';
import 'public_trip_widgets.dart';

/// Shown once the trip has been sent for review.
class PublicTripSubmittedBody extends StatelessWidget {
  const PublicTripSubmittedBody({super.key, required this.onDone});

  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircleAvatar(
            radius: 36,
            backgroundColor: AppColors.lockedFill,
            child: Icon(Icons.check, size: 36, color: AppColors.accent),
          ),
          const SizedBox(height: 20),
          const Text(
            'Sent for review',
            style: AppTextStyles.detailTitle,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            "A moderator will look at it soon. It isn't visible to anyone until it is approved. You can see its status, or withdraw it, from Share trip.",
            style: AppTextStyles.bodyMuted,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),
          PublicTripPrimaryButton(label: 'Done', onPressed: onDone),
        ],
      ),
    );
  }
}
