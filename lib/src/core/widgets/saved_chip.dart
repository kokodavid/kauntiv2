import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../design/app_colors.dart';
import '../domain/saved_at_label.dart';
import '../services/connectivity_provider.dart';

/// Where a [SavedChip] sits, which decides its fill.
enum SavedChipTone {
  /// On the grey page, by a title: white with a border.
  page,

  /// On a white card or sheet: soft grey.
  onWhite,

  /// Over a map or photo: dark glass.
  onMap,
}

/// Marks content shown from the copy kept on the phone: "Saved 3 weeks ago"
/// (Offline States 03). Only visible while offline; never interactive.
class SavedChip extends ConsumerWidget {
  const SavedChip({
    super.key,
    required this.savedAt,
    this.tone = SavedChipTone.page,
  });

  final DateTime savedAt;
  final SavedChipTone tone;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(connectivityProvider.select((s) => s.isOffline))) {
      return const SizedBox.shrink();
    }
    return SavedChipBody(savedAt: savedAt, tone: tone);
  }
}

/// The chip itself, for a screen already showing a saved copy that wants it
/// whether or not the phone has since reconnected.
class SavedChipBody extends StatelessWidget {
  const SavedChipBody({
    super.key,
    required this.savedAt,
    this.tone = SavedChipTone.page,
  });

  final DateTime savedAt;
  final SavedChipTone tone;

  @override
  Widget build(BuildContext context) {
    final onMap = tone == SavedChipTone.onMap;
    final label = savedAtLabel(savedAt, DateTime.now()) ?? 'Saved';
    return Container(
      height: 26,
      padding: const EdgeInsets.only(left: 8, right: 10),
      decoration: BoxDecoration(
        color: switch (tone) {
          SavedChipTone.page => Colors.white,
          SavedChipTone.onWhite => AppColors.offlineIconCircle,
          SavedChipTone.onMap => const Color(0xD1181B18),
        },
        borderRadius: BorderRadius.circular(999),
        border: switch (tone) {
          SavedChipTone.page => Border.all(color: AppColors.cardBorder),
          SavedChipTone.onWhite => null,
          SavedChipTone.onMap => Border.all(
            color: Colors.white.withValues(alpha: 0.12),
          ),
        },
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.cloud_off_rounded,
            size: 13,
            color: onMap
                ? AppColors.offlinePillIcon
                : AppColors.mutedForeground,
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: onMap ? const Color(0xFFE4E4E7) : AppColors.offlineBody,
            ),
          ),
        ],
      ),
    );
  }
}
