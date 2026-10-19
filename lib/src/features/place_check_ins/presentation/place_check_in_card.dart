import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/app_type_scale.dart';
import '../../../design/app_colors.dart';
import '../application/place_check_in_providers.dart';
import 'check_in_messages.dart';

/// "Been here? Check in": one tap reads the position and asks the server.
/// A check-in is what builds a county's Bronze, Silver and Gold, so the card
/// says what it does. Hidden while the dashboard has check-ins off.
class PlaceCheckInCard extends ConsumerWidget {
  const PlaceCheckInCard({
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
    final busy = controller.isLoading;
    final outcome = controller.value;
    final message = controller.hasError
        ? checkInErrorMessage
        : outcome == null
        ? null
        : checkInMessage(outcome, placeName);
    final done = status.checkedInToday || (outcome?.counted ?? false);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.cardBorder),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                done ? Icons.check_circle : Icons.place_outlined,
                size: 22,
                color: done ? AppColors.accent : AppColors.mutedForeground,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  done ? 'Checked in today' : 'Been here?',
                  style: const TextStyle(
                    fontFamily: AppTypeScale.family,
                    fontSize: AppTypeScale.cardTitleSize,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF18181B),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            status.visits > 0
                ? 'Checked in on ${status.visits} '
                      '${status.visits == 1 ? 'day' : 'days'}. Places you check '
                      'in at count toward Bronze, Silver and Gold.'
                : 'Check in when you are here. Places you check in at count '
                      'toward Bronze, Silver and Gold.',
            style: const TextStyle(
              fontFamily: AppTypeScale.family,
              fontSize: AppTypeScale.bodySize,
              height: 1.4,
              color: AppColors.mutedForeground,
            ),
          ),
          if (!done) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: FilledButton(
                onPressed: busy
                    ? null
                    : () => ref
                          .read(
                            placeCheckInControllerProvider(placeId).notifier,
                          )
                          .checkIn(),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: AppColors.accentForeground,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: busy
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text("I'm here"),
              ),
            ),
          ],
          if (message != null) ...[
            const SizedBox(height: 10),
            Text(
              message,
              style: TextStyle(
                fontFamily: AppTypeScale.family,
                fontSize: AppTypeScale.smallSize,
                height: 1.4,
                color: (outcome?.counted ?? false)
                    ? AppColors.accent
                    : AppColors.mutedForeground,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
