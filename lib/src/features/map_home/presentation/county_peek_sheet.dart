import 'package:flutter/material.dart';

import '../../../core/domain/app_stat_format.dart';
import '../../../core/widgets/app_feature_card.dart';
import '../../../design/app_colors.dart';
import '../../../design/app_text_styles.dart';
import '../../discover/domain/explore_labels.dart';
import '../domain/map_home_models.dart';

/// The county preview from the map: the same feature card as Explore
/// (photo, headquarters, places line, stats, county shape), with the
/// traveller's standing on the photo, and "Open County".
class CountyPeekSheet extends StatelessWidget {
  const CountyPeekSheet({
    super.key,
    required this.badge,
    required this.isHome,
    this.onOpen,
  });

  final MapHomeCountyBadge badge;
  final bool isHome;

  /// Opens County Detail after the sheet closes; null just closes it.
  final VoidCallback? onOpen;

  static Future<void> show(
    BuildContext context,
    MapHomeCountyBadge badge, {
    required bool isHome,
    VoidCallback? onOpen,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      // Over the tab bar, not inside the tab's own navigator.
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      barrierColor: AppColors.foreground.withValues(alpha: 0.28),
      builder: (context) =>
          CountyPeekSheet(badge: badge, isHome: isHome, onOpen: onOpen),
    );
  }

  void _open(BuildContext context) {
    Navigator.of(context).pop();
    onOpen?.call();
  }

  @override
  Widget build(BuildContext context) {
    final county = badge.county;
    final hq = badge.headquarters;
    return Container(
      // The white runs under the home indicator; only the content is inset.
      padding: EdgeInsets.fromLTRB(
        16,
        0,
        16,
        16 + MediaQuery.paddingOf(context).bottom,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _Handle(),
          AppFeatureCard(
            county: county,
            label: isHome ? 'HOME COUNTY' : badge.state.statusLabel,
            photoTitle: county.name,
            photoCaption: hq == null ? '${county.name} County' : 'HQ · $hq',
            photoUrl: badge.highlightImageUrl,
            line: ExploreLabels.blurb(badge.placeNames),
            stats: AppStatFormat.stats(
              areaKm2: badge.areaKm2,
              elevationM: badge.elevationM,
              durationMinutes: badge.durationMinutes,
            ),
            onTap: () => _open(context),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () => _open(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              child: const Text(
                'Open County',
                style: AppTextStyles.buttonLabel,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Handle extends StatelessWidget {
  const _Handle();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: AppColors.trackInactive,
            borderRadius: BorderRadius.circular(999),
          ),
        ),
      ),
    );
  }
}
