import 'package:flutter/material.dart';

import '../../../design/app_colors.dart';
import '../../../design/app_text_styles.dart';
import '../domain/public_trip_owner_view.dart';

/// The small badge showing where a public trip stands.
class PublicTripStatusChip extends StatelessWidget {
  const PublicTripStatusChip({super.key, required this.phase});

  final PublicTripPhase phase;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (phase) {
      PublicTripPhase.awaitingReview => (
        'Awaiting review',
        AppColors.pendingFill,
      ),
      PublicTripPhase.isPublic => ('Public', AppColors.legendHome),
      PublicTripPhase.needsChanges => ('Needs changes', AppColors.danger),
      PublicTripPhase.hidden => ('Hidden', AppColors.mutedForeground),
      PublicTripPhase.none => ('', AppColors.mutedForeground),
    };
    if (phase == PublicTripPhase.none) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(label, style: AppTextStyles.chipLabel.copyWith(color: color)),
    );
  }
}
