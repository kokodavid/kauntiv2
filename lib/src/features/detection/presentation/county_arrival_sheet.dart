import 'package:flutter/material.dart';

import '../../../core/design/app_type_scale.dart';
import '../../../design/app_colors.dart';
import '../../../widgets/app_county_shape.dart';
import '../../discover/domain/county_detail.dart';
import 'arrival_place_rows.dart';

/// The "you've crossed into X" sheet (v1 `county_arrival_sheet.dart`,
/// doc 03 board 15d) on the shared type scale: county shape and "N worth
/// the detour.", up to four places, a link to all of them, the privacy
/// note, and Explore / Dismiss. [data] is already loaded, so the sheet
/// opens complete.
///
/// [onOpenCounty] and [onOpenPlace] run after the sheet closes; null hides
/// the county actions (no detail pages in this build).
Future<void> showCountyArrivalSheet(
  BuildContext context, {
  required CountyDetailData data,
  void Function(int countyCode)? onOpenCounty,
  void Function(String placeId)? onOpenPlace,
}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.exploreSurface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
    ),
    showDragHandle: true,
    isScrollControlled: true,
    builder: (sheetContext) {
      void closeThen(VoidCallback action) {
        Navigator.of(sheetContext).pop();
        action();
      }

      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 0, 22, 20),
          child: _ArrivalContent(
            data: data,
            onOpenCounty: onOpenCounty == null
                ? null
                : () => closeThen(() => onOpenCounty(data.county.code)),
            onOpenPlace: onOpenPlace == null
                ? null
                : (id) => closeThen(() => onOpenPlace(id)),
            onDismiss: () => Navigator.of(sheetContext).pop(),
          ),
        ),
      );
    },
  );
}

class _ArrivalContent extends StatelessWidget {
  const _ArrivalContent({
    required this.data,
    required this.onDismiss,
    this.onOpenCounty,
    this.onOpenPlace,
  });

  final CountyDetailData data;
  final VoidCallback onDismiss;
  final VoidCallback? onOpenCounty;
  final void Function(String placeId)? onOpenPlace;

  static const _greenLabel = TextStyle(
    fontFamily: AppTypeScale.family,
    fontSize: AppTypeScale.metaSize,
    fontWeight: FontWeight.w600,
    letterSpacing: AppTypeScale.metaTracking,
    color: AppColors.green,
  );

  @override
  Widget build(BuildContext context) {
    final name = data.county.name;
    final count = data.places.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            SizedBox(
              width: 38,
              height: 62,
              child: AppCountyShape(
                county: data.county,
                fill: AppColors.green.withValues(alpha: 0.9),
              ),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("You've crossed into $name", style: _greenLabel),
                  const SizedBox(height: 2),
                  Text(
                    count == 0
                        ? 'Nothing on file here yet.'
                        : '$count worth the detour.',
                    style: AppTypeScale.sectionTitle,
                  ),
                ],
              ),
            ),
          ],
        ),
        if (count > 0) ...[
          const SizedBox(height: 8),
          ArrivalPlaceRows(data: data, onOpenPlace: onOpenPlace),
          if (onOpenCounty case final open?)
            InkWell(
              onTap: open,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.only(top: 10, bottom: 2),
                decoration: const BoxDecoration(
                  border: Border(
                    top: BorderSide(color: AppColors.exploreBorder),
                  ),
                ),
                child: Text(
                  'All $count ${count == 1 ? 'place' : 'places'} in $name →',
                  textAlign: TextAlign.center,
                  style: _greenLabel,
                ),
              ),
            ),
        ],
        const SizedBox(height: 12),
        _PrivacyNote(countyName: name),
        const SizedBox(height: 14),
        Row(
          children: [
            if (onOpenCounty case final open?)
              Expanded(
                child: FilledButton(
                  onPressed: open,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Explore $name',
                    style: AppTypeScale.action.copyWith(color: Colors.white),
                  ),
                ),
              )
            else
              const Spacer(),
            const SizedBox(width: 8),
            TextButton(
              onPressed: onDismiss,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.mutedForeground,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
              child: const Text('Dismiss'),
            ),
          ],
        ),
      ],
    );
  }
}

/// Doc 05: the app knows the county, never the spot inside it.
class _PrivacyNote extends StatelessWidget {
  const _PrivacyNote({required this.countyName});

  final String countyName;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.exploreCategoryFill,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.shield_outlined,
            size: 15,
            color: AppColors.exploreCategoryText,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              "We know you're in $countyName, not where you are in it.",
              style: AppTypeScale.small.copyWith(
                color: AppColors.exploreCategoryText,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
