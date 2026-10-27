import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/badges_providers.dart';
import '../domain/county_badge_detail.dart';
import '../domain/passport_county.dart';
import '../domain/passport_progress.dart';
import '../domain/passport_rules.dart';
import 'passport_ad_slot.dart';
import 'passport_callbacks.dart';
import 'passport_county_skeleton.dart';
import 'passport_hero_card.dart';
import 'passport_links_card.dart';
import 'passport_next_stamp_card.dart';
import 'passport_places_card.dart';
import 'passport_stats_row.dart';

/// One county page: hero, next stamp, places discovered, the user's time
/// there and a way into the county. Scrolls on its own.
class PassportCountyView extends ConsumerWidget {
  const PassportCountyView({
    super.key,
    required this.county,
    this.onOpenCounty,
    this.rules = PassportRules.standard,
  });

  final PassportCounty county;
  final PassportOpenCounty? onOpenCounty;
  final PassportRules rules;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Loading or offline: the page still shows its level; the figures that
    // need the server stay at zero until they arrive.
    final async = ref.watch(countyBadgeDetailProvider(county.code));
    final detail = async.value ?? const CountyBadgeDetail();
    // First load only: a refresh keeps showing the figures it has.
    final loading = async.isLoading && !async.hasValue;
    final evidence = PassportEvidence(
      places: [
        for (final p in detail.checkedInPlaces)
          VerifiedPlace(
            id: p.id,
            name: p.name,
            category: p.category,
            visitedAt: p.visitedAt,
            thumbnailUrl: p.thumbnailUrl,
          ),
      ],
      visitDays: detail.checkInDays,
    );
    final progress = PassportProgress.of(
      level: county.level,
      detail: detail,
      rules: rules,
      evidence: evidence,
    );
    final open = onOpenCounty;
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(18, 4, 18, 40),
      children: [
        PassportHeroCard(county: county, detail: detail, progress: progress),
        const SizedBox(height: 14),
        if (loading)
          const PassportCountyCardsSkeleton()
        else ...[
          PassportNextStampCard(
            county: county,
            progress: progress,
            rules: rules,
          ),
          if (rules.placeVerificationLive) ...[
            const SizedBox(height: 14),
            PassportPlacesCard(
              places: evidence.places,
              total: detail.placesTotal,
            ),
          ],
          if (detail.hasTimeHere) ...[
            const SizedBox(height: 14),
            PassportStatsRow(county: county.name, detail: detail),
          ],
        ],
        const SizedBox(height: 14),
        const PassportAdSlot(),
        PassportLinksCard(
          county: county.name,
          onOpen: open == null ? null : () => open(context, county.code),
        ),
      ],
    );
  }
}
