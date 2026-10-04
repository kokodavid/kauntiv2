import 'package:flutter/material.dart';

import '../../../design/app_colors.dart';
import '../../../design/app_text_styles.dart';

/// The neutral state for a trip that cannot be shown. It never says why
/// (withdrawn, hidden, blocked or removed look the same), so it reveals
/// nothing about the author or the moderation outcome.
class PublicTripUnavailable extends StatelessWidget {
  const PublicTripUnavailable({super.key, this.offline = false, this.onRetry});

  /// The trip could not be checked, rather than being gone.
  final bool offline;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              offline ? Icons.wifi_off_rounded : Icons.public_off,
              size: 40,
              color: AppColors.mutedForeground,
            ),
            const SizedBox(height: 14),
            Text(
              offline ? "Can't check this trip" : 'This trip is not available',
              style: AppTextStyles.heading,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              offline
                  ? 'Public trips only show while we can confirm they are '
                        'still shared. Check your connection and try again.'
                  : 'It may have been taken down by its owner.',
              style: AppTextStyles.bodyMuted,
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 18),
              OutlinedButton(
                onPressed: onRetry,
                child: const Text('Try again'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
