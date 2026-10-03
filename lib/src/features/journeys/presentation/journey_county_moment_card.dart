import 'package:flutter/material.dart';

import '../../../app/detail_routes.dart';
import '../../../core/design/app_type_scale.dart';
import '../../../counties/county_paths.dart';
import '../../../design/app_colors.dart';
import '../../../widgets/county_badge_medallion.dart';
import '../../badges/domain/badge_collection.dart';
import '../domain/journey_county_moment_facts.dart';

/// The "Entered county" timeline row's body (Claude-Design "Entered
/// County Card 1b: overlay"): a 16:10 hero with the county's depth coin
/// and name overlaid on it, one fact line below when any is on file, and
/// a footer pairing a personal line with how many places there are to
/// explore. Missing facts are dropped, never shown as a placeholder -
/// same rule County Detail already follows. The whole card is its own
/// tap target to County Detail, distinct from the row's own tap (which
/// jumps replay to this point).
class JourneyCountyMomentCard extends StatefulWidget {
  const JourneyCountyMomentCard({
    super.key,
    required this.county,
    required this.facts,
  });

  final CountyPath county;

  /// Null while the batched facts query is still loading, or when this
  /// county has no row in `counties` yet - the card still shows, just
  /// with the name and coin only.
  final JourneyCountyMomentFacts? facts;

  @override
  State<JourneyCountyMomentCard> createState() =>
      _JourneyCountyMomentCardState();
}

class _JourneyCountyMomentCardState extends State<JourneyCountyMomentCard> {
  var _pressed = false;

  void _open() {
    final open = DetailRoutes.openCounty;
    if (open == null) return;
    open(context, widget.county.code);
  }

  @override
  Widget build(BuildContext context) {
    final facts = widget.facts;
    final hasPhoto = facts?.hasPhoto ?? false;
    final earned = facts != null && facts.depth.index > 0;
    final factLine = facts?.factLine;
    final placesCount = facts?.placesCount ?? 0;

    return GestureDetector(
      onTap: _open,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.98 : 1,
        duration: const Duration(milliseconds: 100),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: ColoredBox(
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                AspectRatio(
                  aspectRatio: hasPhoto ? 16 / 10 : 16 / 7,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (hasPhoto)
                        Image.network(facts!.heroImageUrl!, fit: BoxFit.cover)
                      else
                        const ColoredBox(color: AppColors.lockedFill),
                      if (hasPhoto)
                        const DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              stops: [0, 0.4, 0.75],
                              colors: [
                                Color(0xD9090B0F),
                                Color(0x8C090B0F),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      Positioned(
                        left: 12,
                        right: 12,
                        bottom: 10,
                        child: Row(
                          children: [
                            CountyBadgeMedallion(
                              county: widget.county,
                              earned: earned,
                              size: 36,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.county.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTypeScale.cardTitle.copyWith(
                                      color: hasPhoto
                                          ? Colors.white
                                          : AppColors.foreground,
                                    ),
                                  ),
                                  Text(
                                    '${(facts?.depth ?? CountyDepth.none).label} '
                                    '· ${widget.county.name} County',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTypeScale.small.copyWith(
                                      color: hasPhoto
                                          ? const Color(0xD9FFFFFF)
                                          : AppColors.mutedForeground,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (factLine != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
                    child: Text(
                      factLine,
                      style: AppTypeScale.small.copyWith(
                        color: AppColors.mutedForeground,
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _personLine(facts),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypeScale.small.copyWith(
                            fontWeight: FontWeight.w600,
                            color: facts?.isFirstVisit ?? false
                                ? AppColors.toastSuccessIcon
                                : AppColors.mutedForeground,
                          ),
                        ),
                      ),
                      if (placesCount > 0) ...[
                        const SizedBox(width: 8),
                        Text(
                          '${facts!.placesLabel} to explore',
                          style: AppTypeScale.small.copyWith(
                            color: AppColors.accent,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right,
                          size: 16,
                          color: AppColors.accent,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _personLine(JourneyCountyMomentFacts? facts) {
    if (facts == null) return 'Entered ${widget.county.name}';
    if (facts.isFirstVisit) return 'First time in ${widget.county.name}';
    return 'Visit ${facts.passCount}';
  }
}
