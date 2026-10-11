import 'package:flutter/material.dart';

import '../../../design/app_colors.dart';
import 'detail_widgets.dart';

/// Place Detail's bottom bar, the same on both tabs: the main action
/// (Start trip, or Get Route) with Share and Save beside it. Content ends
/// above it; nothing scrolls underneath.
class PlaceDetailBar extends StatelessWidget {
  const PlaceDetailBar({
    super.key,
    required this.primary,
    required this.saved,
    required this.onSavedChanged,
    required this.onShare,
  });

  final Widget primary;
  final bool saved;
  final Future<void> Function(bool saved) onSavedChanged;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        10,
        16,
        MediaQuery.paddingOf(context).bottom + 10,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.cardBorder)),
      ),
      child: Row(
        children: [
          Expanded(child: primary),
          const SizedBox(width: 10),
          DetailGlassButton(
            icon: Icons.ios_share,
            tooltip: 'Share',
            size: 44,
            background: AppColors.secondaryFill,
            onPressed: onShare,
          ),
          const SizedBox(width: 8),
          DetailSaveButton(
            saved: saved,
            size: 44,
            background: AppColors.secondaryFill,
            onChanged: onSavedChanged,
          ),
        ],
      ),
    );
  }
}
