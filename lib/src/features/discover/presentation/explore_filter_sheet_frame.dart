import 'package:flutter/material.dart';

import '../../../core/design/app_type_scale.dart';
import '../../../design/app_colors.dart';

/// The filter sheet's pinned top: drag handle, title and Reset. It stays in
/// view while the filters below scroll.
class ExploreSheetHeader extends StatelessWidget {
  const ExploreSheetHeader({super.key, required this.onReset});

  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 5,
            decoration: BoxDecoration(
              color: AppColors.trackInactive,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Expanded(
                child: Text('Filters', style: AppTypeScale.sectionTitle),
              ),
              TextButton(
                onPressed: onReset,
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.accent,
                  minimumSize: const Size(44, 44),
                  textStyle: const TextStyle(
                    fontFamily: AppTypeScale.family,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                child: const Text('Reset'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// The filter sheet's pinned bottom: the "Show N places" button under a
/// hairline, always in view however long the filters get.
class ExploreSheetFooter extends StatelessWidget {
  const ExploreSheetFooter({
    super.key,
    required this.label,
    required this.onPressed,
  });

  final String label;

  /// Null while nothing matches.
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.exploreBorder)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
        child: FilledButton(
          onPressed: onPressed,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.accent,
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(52),
            shape: const StadiumBorder(),
            textStyle: const TextStyle(
              fontFamily: AppTypeScale.family,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          child: Text(label),
        ),
      ),
    );
  }
}
