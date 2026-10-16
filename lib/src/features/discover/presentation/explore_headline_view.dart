import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/app_type_scale.dart';
import '../../../design/app_colors.dart';
import '../../../services/app_location_permission_service.dart';
import '../../onboarding/application/startup_flow.dart';
import '../domain/explore_headline.dart';
import 'explore_styles.dart';

/// The 24pt Places sentence with its accent phrase, plus whatever sits
/// under it in the design: the interests line or the location-off card.
class ExploreHeadlineView extends ConsumerWidget {
  const ExploreHeadlineView({
    super.key,
    required this.headline,
    this.interestLabels = const [],
    this.onEditInterests,
    this.locationOff = false,
  });

  final ExploreHeadline headline;
  final List<String> interestLabels;
  final VoidCallback? onEditInterests;
  final bool locationOff;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text.rich(
            TextSpan(
              children: [
                TextSpan(text: headline.before),
                TextSpan(
                  text: headline.accent,
                  style: const TextStyle(color: AppColors.accent),
                ),
                TextSpan(text: headline.after),
              ],
            ),
            style: ExploreStyles.resultsSentence,
          ),
          if (interestLabels.isNotEmpty) ...[
            const SizedBox(height: 12),
            _InterestsLine(labels: interestLabels, onEdit: onEditInterests),
          ],
          if (locationOff) ...[
            const SizedBox(height: 12),
            _LocationOffCard(
              onTurnOn: () async {
                final service = ref.read(locationPermissionServiceProvider);
                final result = await service.requestLocationAccess();
                if (result != AppLocationPermissionResult.granted) {
                  await service.openSettings();
                }
              },
            ),
          ],
        ],
      ),
    );
  }
}

class _InterestsLine extends StatelessWidget {
  const _InterestsLine({required this.labels, this.onEdit});

  final List<String> labels;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    const style = TextStyle(
      fontFamily: AppTypeScale.family,
      fontSize: 12,
      color: AppColors.mutedForeground,
    );
    return Row(
      children: [
        const Icon(Icons.tune, size: 16, color: AppColors.mutedForeground),
        const SizedBox(width: 6),
        Expanded(
          child: Text.rich(
            TextSpan(
              style: style,
              children: [
                TextSpan(text: 'For ${labels.join(', ')} · '),
                WidgetSpan(
                  alignment: PlaceholderAlignment.baseline,
                  baseline: TextBaseline.alphabetic,
                  child: GestureDetector(
                    onTap: onEdit,
                    child: const Text(
                      'Edit',
                      style: TextStyle(
                        fontFamily: AppTypeScale.family,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.mutedForeground,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _LocationOffCard extends StatelessWidget {
  const _LocationOffCard({required this.onTurnOn});

  final VoidCallback onTurnOn;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(14, 6, 6, 6),
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: AppColors.exploreBorder),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Row(
      children: [
        const Icon(
          Icons.location_off_outlined,
          size: 19,
          color: AppColors.mutedForeground,
        ),
        const SizedBox(width: 10),
        const Expanded(
          child: Text(
            'Location is off, so distances are hidden.',
            style: TextStyle(
              fontFamily: AppTypeScale.family,
              fontSize: 12,
              color: AppColors.mutedForeground,
            ),
          ),
        ),
        Material(
          color: AppColors.accentTint,
          shape: const StadiumBorder(),
          child: InkWell(
            onTap: onTurnOn,
            customBorder: const StadiumBorder(),
            child: const SizedBox(
              height: 44,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 14),
                child: Center(
                  child: Text(
                    'Turn on',
                    style: TextStyle(
                      fontFamily: AppTypeScale.family,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.accent,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
