import 'package:flutter/material.dart';

import '../../../core/domain/app_stat_format.dart';
import '../../../design/app_colors.dart';
import '../../../design/app_text_styles.dart';
import '../../../widgets/app_county_shape.dart';
import '../domain/map_home_models.dart';
import 'map_home_county_map_painter.dart';

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

  @override
  Widget build(BuildContext context) {
    final style = MapHomeCountyStyle.forState(badge.state, isHome: isHome);
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
          Center(
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
          ),
          Text('${badge.county.name} County', style: AppTextStyles.heading),
          const SizedBox(height: 12),
          Container(
            height: 190,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFE6F3FF), Color(0x14DBEEFF)],
              ),
              border: Border.all(color: AppColors.cardBorder),
              borderRadius: BorderRadius.circular(25),
            ),
            child: Center(
              child: SizedBox(
                width: 150,
                height: 150,
                child: AppCountyShape(
                  county: badge.county,
                  fill: style.fill,
                  stroke: style.stroke,
                  strokeWidth: 1.2,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          _FactRow(badge: badge),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                onOpen?.call();
              },
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

class _FactRow extends StatelessWidget {
  const _FactRow({required this.badge});

  final MapHomeCountyBadge badge;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _Fact(label: 'Area', value: _formatArea(badge.areaKm2)),
        const SizedBox(width: 19),
        _Fact(label: 'Elevation', value: _formatElevation(badge.elevationM)),
        const SizedBox(width: 19),
        _Fact(label: 'Duration', value: _formatDuration(badge.durationMinutes)),
      ],
    );
  }

  String _formatArea(num? value) =>
      value == null ? 'Not on file' : AppStatFormat.area(value);

  String _formatElevation(num? value) =>
      value == null ? 'Not on file' : AppStatFormat.elevation(value);

  String _formatDuration(int? minutes) =>
      minutes == null ? 'Not on file' : AppStatFormat.duration(minutes);
}

class _Fact extends StatelessWidget {
  const _Fact({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.chipLabel,
          ),
          Text(label, style: AppTextStyles.bodySmall),
        ],
      ),
    );
  }
}
