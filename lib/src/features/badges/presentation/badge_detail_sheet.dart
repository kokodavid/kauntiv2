import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/app_type_scale.dart';
import '../../../core/services/app_share.dart';
import '../../../design/app_colors.dart';
import '../application/badges_providers.dart';
import '../domain/badge_collection.dart';
import 'badge_coin.dart';
import 'badge_detail_sections.dart';
import 'badge_share_card.dart';
import 'badge_sheet_parts.dart';

/// Opens County Detail / Place Detail; supplied by `app/`.
typedef OpenBadgeCounty = void Function(BuildContext context, int countyCode);
typedef OpenBadgePlace = void Function(BuildContext context, String placeId);

/// A badge up close: the badge card, when it was earned and what the next
/// depth needs, your visits / last visit / Journeys there, Share (earned)
/// and View county. An earned coin spins the first time its sheet opens,
/// and again when tapped. A county not yet earned shows how to earn it and
/// places to start with.
class BadgeDetailSheet extends ConsumerStatefulWidget {
  const BadgeDetailSheet({
    super.key,
    required this.badge,
    required this.claimed,
    required this.total,
    this.onOpenCounty,
    this.onOpenPlace,
  });

  final CountyBadge badge;
  final int claimed;
  final int total;
  final VoidCallback? onOpenCounty;
  final ValueChanged<String>? onOpenPlace;

  /// Shows the sheet; the open callbacks run after it closes, with the
  /// screen's [context].
  static Future<void> show(
    BuildContext context, {
    required CountyBadge badge,
    required BadgeCollection collection,
    OpenBadgeCounty? onOpenCounty,
    OpenBadgePlace? onOpenPlace,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      // Over the tab bar.
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: AppColors.foreground.withValues(alpha: 0.28),
      builder: (sheetContext) {
        void closeThen(void Function() open) {
          Navigator.of(sheetContext).pop();
          open();
        }

        return BadgeDetailSheet(
          badge: badge,
          claimed: collection.claimed,
          total: collection.total,
          onOpenCounty: onOpenCounty == null
              ? null
              : () => closeThen(() => onOpenCounty(context, badge.county.code)),
          onOpenPlace: onOpenPlace == null
              ? null
              : (id) => closeThen(() => onOpenPlace(context, id)),
        );
      },
    );
  }

  @override
  ConsumerState<BadgeDetailSheet> createState() => _BadgeDetailSheetState();
}

class _BadgeDetailSheetState extends ConsumerState<BadgeDetailSheet> {
  final _cardKey = GlobalKey();
  bool _sharing = false;

  /// The coin is mid-spin: Share waits so the image shows its front.
  bool _spinning = false;

  Future<void> _share() async {
    if (_sharing) return;
    setState(() => _sharing = true);
    final messenger = ScaffoldMessenger.of(context);
    final box = context.findRenderObject() as RenderBox?;
    final origin = box == null
        ? null
        : box.localToGlobal(Offset.zero) & box.size;
    try {
      final png = await BadgeShareCard.capture(_cardKey);
      if (png == null) throw StateError('Nothing to capture.');
      final badge = widget.badge;
      await AppShare.image(
        png,
        fileName: 'kaunti47-${badge.county.slug}.png',
        text:
            'I earned the ${badge.county.name} badge on Kaunti47 '
            '(${widget.claimed} of ${widget.total} counties).',
        origin: origin,
      );
    } on Object {
      messenger.showSnackBar(
        const SnackBar(content: Text("Couldn't share the badge. Try again.")),
      );
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final badge = widget.badge;
    final detail = ref.watch(countyBadgeDetailProvider(badge.county.code));
    // Start the position read alongside the details: places to start
    // with are sorted by distance.
    if (!badge.isEarned) ref.watch(badgeUserLocationProvider);
    // An earned coin spins the first time its sheet opens.
    final spin =
        badge.isEarned &&
        (ref.watch(badgeFirstSpinProvider(badge.county.code)).value ??
            false);
    final openCounty = widget.onOpenCounty;
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.9,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          16,
          10,
          16,
          16 + MediaQuery.paddingOf(context).bottom,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const BadgeSheetHandle(),
            RepaintBoundary(
              key: _cardKey,
              child: BadgeShareCard(
                badge: badge,
                claimed: widget.claimed,
                total: widget.total,
                coinBuilder: (size) => BadgeCoin(
                  badge: badge,
                  size: size,
                  spinOnStart: spin,
                  onSpinningChanged: (spinning) {
                    if (mounted) setState(() => _spinning = spinning);
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
            switch (detail) {
              AsyncValue(:final value?) => Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (badge.isEarned) ...[
                    BadgeProgressSection(badge: badge, detail: value),
                    const SizedBox(height: 12),
                    BadgeTimeSection(
                      countyName: badge.county.name,
                      detail: value,
                    ),
                  ] else
                    BadgeHowToEarnSection(
                      badge: badge,
                      detail: value,
                      onOpenPlace: widget.onOpenPlace,
                    ),
                ],
              ),
              AsyncValue(hasError: true) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        "Couldn't load the details. Check your connection.",
                        style: AppTypeScale.small,
                      ),
                    ),
                    TextButton(
                      onPressed: () => ref.invalidate(
                        countyBadgeDetailProvider(badge.county.code),
                      ),
                      child: const Text('Try again'),
                    ),
                  ],
                ),
              ),
              _ => const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              ),
            },
            const SizedBox(height: 16),
            Row(
              children: [
                if (badge.isEarned) ...[
                  Expanded(
                    child: BadgeSheetButton(
                      label: 'Share',
                      icon: Icons.ios_share,
                      filled: true,
                      onPressed: _sharing || _spinning
                          ? null
                          : () => unawaited(_share()),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                if (openCounty != null)
                  Expanded(
                    child: BadgeSheetButton(
                      label: 'View county',
                      icon: Icons.map_outlined,
                      filled: !badge.isEarned,
                      onPressed: openCounty,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
