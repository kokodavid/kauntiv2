import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/app_type_scale.dart';
import '../../../core/widgets/interest_icon.dart';
import '../../../design/app_colors.dart';
import '../../profile/application/interests_providers.dart';
import '../../profile/domain/place_interest.dart';
import 'explore_styles.dart';

/// Explore for a traveller with no interests yet (design frame 4e): the
/// headline becomes a question with the eight interests inline. Tapping one
/// toggles it (saved at once, any number), and "Near you" follows
/// underneath. An invitation, not a gate.
class ExploreInterestPrompt extends ConsumerWidget {
  const ExploreInterestPrompt({super.key, required this.onDone});

  /// Dismisses the question once the traveller has picked what they like.
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final picks = switch (ref.watch(myInterestsProvider)) {
      AsyncData(:final value) => value.interests,
      _ => const <PlaceInterest>[],
    };
    final options =
        ref.watch(interestCatalogueProvider).value ?? PlaceInterest.values;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('What are you into?', style: ExploreStyles.resultsSentence),
        const SizedBox(height: 12),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final interest in options)
              _InterestChip(
                interest: interest,
                selected: picks.contains(interest),
                onTap: () => ref.read(myInterestsProvider.notifier).save([
                  for (final other in options)
                    if (other == interest
                        ? !picks.contains(interest)
                        : picks.contains(other))
                      other,
                ]),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            const Expanded(
              child: Text(
                'Change them anytime in Profile.',
                style: TextStyle(
                  fontFamily: AppTypeScale.family,
                  fontSize: AppTypeScale.smallSize,
                  color: AppColors.mutedForeground,
                ),
              ),
            ),
            if (picks.isNotEmpty)
              TextButton(
                onPressed: onDone,
                child: const Text(
                  'Done',
                  style: TextStyle(
                    fontFamily: AppTypeScale.family,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.accent,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _InterestChip extends StatelessWidget {
  const _InterestChip({
    required this.interest,
    required this.selected,
    required this.onTap,
  });

  final PlaceInterest interest;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: selected ? AppColors.accent : AppColors.exploreSurface,
    shape: StadiumBorder(
      side: BorderSide(
        color: selected ? AppColors.accent : AppColors.exploreBorder,
      ),
    ),
    child: InkWell(
      onTap: onTap,
      customBorder: const StadiumBorder(),
      child: SizedBox(
        height: 36,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 0, 12, 0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              InterestIcon(
                iconName: interest.iconName,
                imageUrl: interest.iconUrl,
                size: 17,
                color: selected ? Colors.white : AppColors.mutedForeground,
              ),
              const SizedBox(width: 5),
              Text(
                interest.label,
                style: AppTypeScale.pill.copyWith(
                  color: selected ? Colors.white : AppColors.exploreMutedText,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
