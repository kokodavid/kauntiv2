import 'package:flutter/material.dart';

import '../../../design/app_colors.dart';
import '../../../design/app_text_styles.dart';
import '../domain/public_trip_view.dart';
import 'public_trip_format.dart';

/// Who published the trip and when it happened: avatar, name, handle and the
/// trip's calendar date.
class PublicTripAuthorHeader extends StatelessWidget {
  const PublicTripAuthorHeader({super.key, required this.trip});

  final PublicTripView trip;

  @override
  Widget build(BuildContext context) {
    final author = trip.author;
    final date = publicTripDateLabel(trip.tripDate);
    return Row(
      children: [
        _Avatar(author: author),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                author.displayName,
                style: AppTextStyles.listItemTitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (author.handle != null || date.isNotEmpty)
                Text(
                  [
                    if (author.handle != null) '@${author.handle}',
                    if (date.isNotEmpty) date,
                  ].join('  ·  '),
                  style: AppTextStyles.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.author});

  final PublicTripAuthor author;

  @override
  Widget build(BuildContext context) {
    final url = author.avatarUrl;
    final initial = author.displayName.characters.first.toUpperCase();
    return CircleAvatar(
      radius: 22,
      backgroundColor: AppColors.accent.withValues(alpha: 0.12),
      foregroundImage: url == null || url.isEmpty ? null : NetworkImage(url),
      child: Text(
        initial,
        style: AppTextStyles.listItemTitle.copyWith(color: AppColors.accent),
      ),
    );
  }
}
