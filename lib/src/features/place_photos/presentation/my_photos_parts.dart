import 'package:flutter/material.dart';

import '../../../core/design/app_type_scale.dart';
import '../../../design/app_colors.dart';
import '../domain/photo_submission.dart';
import 'my_photo_row.dart';

class MyPhotosGroup extends StatelessWidget {
  const MyPhotosGroup({
    super.key,
    required this.title,
    required this.note,
    required this.foot,
    required this.rows,
    required this.handle,
    required this.unseen,
    required this.onOpenPlace,
    required this.onRemove,
    required this.onDismiss,
  });

  final String title;
  final String note;
  final String? foot;
  final List<PhotoSubmission> rows;
  final String? handle;
  final Set<String> unseen;
  final void Function(String placeId) onOpenPlace;
  final void Function(PhotoSubmission) onRemove;
  final void Function(PhotoSubmission) onDismiss;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    spacing: 10,
    children: [
      Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        spacing: 8,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontFamily: AppTypeScale.family,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            note,
            style: const TextStyle(
              fontFamily: AppTypeScale.family,
              fontSize: 12,
              color: AppColors.mutedForeground,
            ),
          ),
        ],
      ),
      Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Column(
          children: [
            for (var i = 0; i < rows.length; i++)
              MyPhotoRow(
                key: ValueKey(rows[i].id),
                submission: rows[i],
                handle: handle,
                unseen: unseen.contains(rows[i].id),
                last: i == rows.length - 1,
                onOpenPlace: () => onOpenPlace(rows[i].placeId),
                onRemove: () => onRemove(rows[i]),
                onDismiss: () => onDismiss(rows[i]),
              ),
          ],
        ),
      ),
      if (foot != null)
        Text(
          foot!,
          style: const TextStyle(
            fontFamily: AppTypeScale.family,
            fontSize: 12,
            height: 1.45,
            color: AppColors.mutedForeground,
          ),
        ),
    ],
  );
}

class MyPhotosFilterPill extends StatelessWidget {
  const MyPhotosFilterPill({
    super.key,
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: selected ? AppColors.foreground : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: selected ? null : Border.all(color: AppColors.cardBorder),
      ),
      child: Text(
        '$label  $count',
        style: TextStyle(
          fontFamily: AppTypeScale.family,
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: selected ? Colors.white : AppColors.foreground,
        ),
      ),
    ),
  );
}
