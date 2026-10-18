import 'package:flutter/material.dart';

import '../../../core/design/app_type_scale.dart';
import '../../../design/app_colors.dart';
import '../domain/explore_filters.dart';

/// Small caps section label used by the filter sheet.
const exploreSheetLabel = TextStyle(
  fontFamily: AppTypeScale.family,
  fontSize: AppTypeScale.labelSize,
  fontWeight: FontWeight.w600,
  letterSpacing: AppTypeScale.labelTracking,
  color: AppColors.mutedForeground,
);

/// "HOW FAR FROM YOU" with its value and a five-stop slider.
class ExploreDistanceBlock extends StatelessWidget {
  const ExploreDistanceBlock({
    super.key,
    required this.index,
    required this.onChanged,
  });

  final int index;
  final ValueChanged<int> onChanged;

  static const _stops = ExploreFilters.distanceStops;

  @override
  Widget build(BuildContext context) {
    final value = index >= _stops.length ? 'Any' : '${_stops[index]} km';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            const Text('HOW FAR FROM YOU', style: exploreSheetLabel),
            Text(
              value,
              style: const TextStyle(
                fontFamily: AppTypeScale.family,
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.accent,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 4,
            activeTrackColor: AppColors.accent,
            inactiveTrackColor: AppColors.trackInactive,
            thumbColor: Colors.white,
            overlayShape: SliderComponentShape.noOverlay,
            thumbShape: const RoundSliderThumbShape(
              enabledThumbRadius: 14,
              elevation: 2,
            ),
            tickMarkShape: SliderTickMarkShape.noTickMark,
          ),
          child: Slider(
            value: index.toDouble(),
            max: _stops.length.toDouble(),
            divisions: _stops.length,
            onChanged: (next) => onChanged(next.round()),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (final stop in _stops)
                Text('$stop', style: AppTypeScale.meta),
              const Text('Any', style: AppTypeScale.meta),
            ],
          ),
        ),
      ],
    );
  }
}

/// A sheet pill: a WHERE choice (Anywhere, or A county with a chevron), an
/// interest, or a place type with its icon.
class ExploreWherePill extends StatelessWidget {
  const ExploreWherePill({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.chevron = false,
    this.icon,
  });

  final String label;
  final IconData? icon;
  final bool selected;
  final bool chevron;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? Colors.white : AppColors.exploreMutedText;
    return Material(
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
            padding: EdgeInsets.only(left: 14, right: chevron ? 8 : 14),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 17, color: color),
                  const SizedBox(width: 5),
                ],
                Text(label, style: AppTypeScale.pill.copyWith(color: color)),
                if (chevron) Icon(Icons.chevron_right, size: 17, color: color),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A 56 pt switch row with a leading badge or icon.
class ExploreToggleRow extends StatelessWidget {
  const ExploreToggleRow({
    super.key,
    required this.leading,
    required this.title,
    required this.value,
    required this.onChanged,
    this.subtitle,
  });

  final Widget leading;
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 56),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.exploreBorder)),
      ),
      child: Row(
        children: [
          SizedBox(width: 24, child: Center(child: leading)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: AppTypeScale.family,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.exploreText,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(subtitle!, style: AppTypeScale.small),
                ],
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeTrackColor: AppColors.accent,
          ),
        ],
      ),
    );
  }
}

/// "Pick what you like to filter by it. Choose interests": shown in the
/// FOR YOU spot when the traveller has no interests yet.
class ExploreChooseInterests extends StatelessWidget {
  const ExploreChooseInterests({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Text.rich(
    TextSpan(
      style: const TextStyle(
        fontFamily: AppTypeScale.family,
        fontSize: 13,
        height: 1.5,
        color: AppColors.mutedForeground,
      ),
      children: [
        const TextSpan(text: 'Pick what you like to filter by it. '),
        WidgetSpan(
          alignment: PlaceholderAlignment.baseline,
          baseline: TextBaseline.alphabetic,
          child: GestureDetector(
            onTap: onTap,
            behavior: HitTestBehavior.opaque,
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Choose interests',
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
      ],
    ),
  );
}
