import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../design/app_colors.dart';
import '../../../design/app_text_styles.dart';
import '../application/interests_providers.dart';
import '../domain/place_interest.dart';

/// Home's one-time "Tell us what you like" card, for people who never
/// answered the setup question. It sits at the top of For you and hides
/// itself (taking no space) unless [interestsPromptProvider] says it is
/// due: unanswered, not dismissed, and from the third session on. Dismiss
/// hides it for good; saving picks does too.
class InterestsPromptCard extends ConsumerWidget {
  const InterestsPromptCard({super.key, required this.onPick});

  /// Opens the Interests screen.
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (ref.watch(interestsPromptProvider).value != true) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(16, 16, 8, 16),
        decoration: BoxDecoration(
          color: AppColors.accent.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      'Tell us what you like',
                      style: AppTextStyles.listItemTitle.copyWith(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Dismiss',
                  onPressed: () =>
                      ref.read(interestsPromptProvider.notifier).dismiss(),
                  style: IconButton.styleFrom(
                    minimumSize: const Size(44, 44),
                    foregroundColor: AppColors.mutedForeground,
                  ),
                  icon: const Icon(Icons.close, size: 20),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: const Text(
                "Two taps and For you leans toward the places you'd pick.",
                style: AppTextStyles.bodySmall,
              ),
            ),
            const SizedBox(height: 12),
            const _SampleChips(),
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: onPick,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: AppColors.accentForeground,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Pick interests',
                    style: AppTextStyles.buttonLabel,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Two example interests and "+6", so the card shows what it is asking.
class _SampleChips extends StatelessWidget {
  const _SampleChips();

  @override
  Widget build(BuildContext context) {
    final samples = [
      PlaceInterest.water.label,
      PlaceInterest.coast.label,
      '+${PlaceInterest.values.length - 2}',
    ];
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final label in samples)
          Container(
            height: 30,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              label,
              style: AppTextStyles.chipLabel.copyWith(
                fontWeight: FontWeight.w500,
                fontSize: 12.5,
              ),
            ),
          ),
      ],
    );
  }
}
