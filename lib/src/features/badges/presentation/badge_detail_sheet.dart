import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/app_type_scale.dart';
import '../../../core/services/app_share.dart';
import '../../../design/app_colors.dart';
import '../../../design/app_text_styles.dart';
import '../application/badges_providers.dart';
import '../domain/badge_collection.dart';
import 'badge_detail_sections.dart';
import 'badge_share_card.dart';

/// Opens County Detail / Place Detail; supplied by `app/`.
typedef OpenBadgeCounty = void Function(BuildContext context, int countyCode);
typedef OpenBadgePlace = void Function(BuildContext context, String placeId);

/// A badge up close: the badge card, when it was earned and what the next
/// depth needs, saved places visited and county coverage, Share (earned)
/// and View county. A county not yet earned shows how to earn it and
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
            const _Handle(),
            RepaintBoundary(
              key: _cardKey,
              child: BadgeShareCard(
                badge: badge,
                claimed: widget.claimed,
                total: widget.total,
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
                    BadgeCoverageSection(detail: value),
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
                    child: _SheetButton(
                      label: 'Share',
                      icon: Icons.ios_share,
                      filled: true,
                      onPressed: _sharing ? null : () => unawaited(_share()),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                if (openCounty != null)
                  Expanded(
                    child: _SheetButton(
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

class _SheetButton extends StatelessWidget {
  const _SheetButton({
    required this.label,
    required this.icon,
    required this.filled,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final bool filled;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(24),
    );
    return SizedBox(
      height: 48,
      child: filled
          ? ElevatedButton.icon(
              onPressed: onPressed,
              icon: Icon(icon, size: 18),
              label: Text(label, style: AppTextStyles.buttonLabel),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: AppColors.accentForeground,
                elevation: 0,
                shape: shape,
              ),
            )
          : OutlinedButton.icon(
              onPressed: onPressed,
              icon: Icon(icon, size: 18),
              label: Text(label, style: AppTextStyles.buttonLabelSecondary),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.foreground,
                side: const BorderSide(color: AppColors.cardBorder),
                shape: shape,
              ),
            ),
    );
  }
}

class _Handle extends StatelessWidget {
  const _Handle();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 40,
        height: 4,
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.trackInactive,
          borderRadius: BorderRadius.circular(999),
        ),
      ),
    );
  }
}
