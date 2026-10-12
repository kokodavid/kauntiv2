import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/interest_icons.dart';
import '../../../design/app_colors.dart';
import '../../../design/app_text_styles.dart';
import '../application/interests_providers.dart';
import '../domain/place_interest.dart';

/// Home's one-time "Tell us what you like" card, for people who never
/// answered the setup question. It sits at the top of For you and hides
/// itself (taking no space) unless [interestsPromptProvider] says it is
/// due: unanswered, not dismissed, and from the third session on. Dismiss
/// hides it for good; saving picks does too.
///
/// Compact layout (about 104px): an overlapping icon cluster hints at the
/// set without looking tappable, the title and dismiss share the top row,
/// and the line and a label-sized button share the bottom row.
class InterestsPromptCard extends ConsumerWidget {
  const InterestsPromptCard({super.key, required this.onPick});

  /// Opens the Interests screen.
  final VoidCallback onPick;

  static const _background = Color(0xFFEAF4FF);
  static const _clusterInterests = [
    PlaceInterest.water,
    PlaceInterest.coast,
    PlaceInterest.wild,
    PlaceInterest.views,
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (ref.watch(interestsPromptProvider).value != true) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(14, 14, 8, 14),
        decoration: BoxDecoration(
          color: _background,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const _IconCluster(interests: _clusterInterests),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Tell us what you like',
                    style: AppTextStyles.listItemTitle.copyWith(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                SizedBox(
                  width: 32,
                  height: 32,
                  child: IconButton(
                    tooltip: 'Dismiss',
                    padding: EdgeInsets.zero,
                    onPressed: () =>
                        ref.read(interestsPromptProvider.notifier).dismiss(),
                    color: AppColors.mutedForeground,
                    icon: const Icon(Icons.close, size: 16),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      "Two taps and For you leans toward places you'd pick.",
                      style: AppTextStyles.bodySmall,
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    height: 36,
                    child: ElevatedButton(
                      onPressed: onPick,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        foregroundColor: AppColors.accentForeground,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Pick interests',
                        style: AppTextStyles.buttonLabel.copyWith(
                          fontSize: 13.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Four overlapping white circles carrying the interest icons.
class _IconCluster extends StatelessWidget {
  const _IconCluster({required this.interests});

  final List<PlaceInterest> interests;

  static const _size = 28.0;
  static const _overlap = 8.0;

  @override
  Widget build(BuildContext context) {
    final width = _size + (interests.length - 1) * (_size - _overlap);
    return ExcludeSemantics(
      child: SizedBox(
        width: width,
        height: _size,
        child: Stack(
          children: [
            for (var i = 0; i < interests.length; i++)
              Positioned(
                left: i * (_size - _overlap),
                child: Container(
                  width: _size,
                  height: _size,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: InterestsPromptCard._background,
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    interestIconForKey(interests[i].key),
                    size: 14,
                    color: AppColors.accent,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
