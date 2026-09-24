import 'package:flutter/material.dart';

import '../../../counties/county_paths.dart';
import '../../../design/app_colors.dart';
import '../../../widgets/app_county_shape.dart';
import 'explore_styles.dart';

/// The county accordion shared by Explore's tabs (v1
/// `DiscoverCountyExpandableCard`): shape tile, name, status line, place
/// count and a chevron; tapping the header expands [child].
class ExploreCountyCard extends StatefulWidget {
  const ExploreCountyCard({
    super.key,
    required this.county,
    required this.statusLabel,
    required this.placeCount,
    required this.child,
    this.initiallyExpanded = false,
  });

  final CountyPath county;
  final String statusLabel;
  final int placeCount;
  final Widget child;
  final bool initiallyExpanded;

  @override
  State<ExploreCountyCard> createState() => _ExploreCountyCardState();
}

class _ExploreCountyCardState extends State<ExploreCountyCard> {
  late bool _expanded = widget.initiallyExpanded;

  static const _motion = Duration(milliseconds: 150);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: ExploreStyles.cardDecoration,
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: Column(
          children: [
            InkWell(
              onTap: () => setState(() => _expanded = !_expanded),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
                child: Row(
                  children: [
                    ExploreCountyShapeTile(county: widget.county),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ExploreCountyHeading(
                        name: widget.county.name,
                        statusLabel: widget.statusLabel,
                      ),
                    ),
                    Text(
                      widget.placeCount == 1
                          ? '1 place'
                          : '${widget.placeCount} places',
                      style: ExploreStyles.placeCount,
                    ),
                    const SizedBox(width: 4),
                    AnimatedRotation(
                      turns: _expanded ? .5 : 0,
                      duration: _motion,
                      child: const Icon(
                        Icons.keyboard_arrow_down,
                        size: 18,
                        color: AppColors.exploreMutedText,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            AnimatedCrossFade(
              firstChild: const SizedBox(width: double.infinity),
              secondChild: Column(
                children: [
                  const Divider(height: 1, color: AppColors.exploreBorder),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: widget.child,
                  ),
                ],
              ),
              crossFadeState: _expanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: _motion,
              sizeCurve: Curves.easeOut,
            ),
          ],
        ),
      ),
    );
  }
}

/// County name over its status line, with an optional trailing pill.
class ExploreCountyHeading extends StatelessWidget {
  const ExploreCountyHeading({
    super.key,
    required this.name,
    required this.statusLabel,
    this.pill,
  });

  final String name;
  final String statusLabel;
  final Widget? pill;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Flexible(
              child: Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: ExploreStyles.countyTitle,
              ),
            ),
            if (pill case final pill?) ...[const SizedBox(width: 8), pill],
          ],
        ),
        const SizedBox(height: 2),
        Text(
          statusLabel,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: ExploreStyles.countyMeta,
        ),
      ],
    );
  }
}

/// The 40px county silhouette tile leading each Explore county card.
class ExploreCountyShapeTile extends StatelessWidget {
  const ExploreCountyShapeTile({super.key, required this.county});

  final CountyPath county;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: AppColors.exploreCategoryFill,
        borderRadius: BorderRadius.circular(10),
      ),
      child: AppCountyShape(
        county: county,
        fill: Colors.white,
        stroke: AppColors.trackInactive,
      ),
    );
  }
}

/// "SEE FULL COUNTY PAGE →" at the foot of an expanded county card; just
/// spacing when County Detail isn't available.
class ExploreCountyPageLink extends StatelessWidget {
  const ExploreCountyPageLink({
    super.key,
    required this.countyCode,
    this.onOpenCounty,
  });

  final int countyCode;
  final void Function(BuildContext context, int countyCode)? onOpenCounty;

  @override
  Widget build(BuildContext context) {
    final open = onOpenCounty;
    if (open == null) return const SizedBox(height: 12);
    return InkWell(
      onTap: () => open(context, countyCode),
      child: const Padding(
        padding: EdgeInsets.only(top: 8, bottom: 14),
        child: Text('SEE FULL COUNTY PAGE  →', style: ExploreStyles.link),
      ),
    );
  }
}
