import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/app_type_scale.dart';
import '../../../design/app_colors.dart';
import '../application/place_check_in_providers.dart';
import 'check_in_view.dart';

/// "Been here?" as one quiet row under the place's hero: an icon, a title
/// with one line of status, and an outlined "I'm here" pill. The pill is
/// deliberately not a filled button so Start trip stays the one primary
/// action. Hidden while the dashboard has check-ins off.
class PlaceCheckInCard extends ConsumerWidget {
  const PlaceCheckInCard({
    super.key,
    required this.placeId,
    required this.placeName,
  });

  final String placeId;
  final String placeName;

  static const _ink = Color(0xFF18181B);
  static const _tintBg = Color(0xFFE6F3FF);
  static const _tintTitle = Color(0xFF0B3A75);
  static const _pillBorder = Color(0xFFCFE6FF);
  static const _pillText = Color(0xFF0A5FD4);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(placeCheckInStatusProvider(placeId)).value;
    if (status == null || !status.enabled) return const SizedBox.shrink();
    final controller = ref.watch(placeCheckInControllerProvider(placeId));
    final view = CheckInView.of(
      status: status,
      outcome: controller.value,
      placeName: placeName,
      busy: controller.isLoading,
      failed: controller.hasError,
    );
    final action = view.action;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: view.tinted ? _tintBg : Colors.transparent,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          _Badge(icon: view.icon, tinted: view.tinted),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  view.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: AppTypeScale.family,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: view.tinted ? _tintTitle : _ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  view.sub,
                  style: TextStyle(
                    fontFamily: AppTypeScale.family,
                    fontSize: 12,
                    height: 1.35,
                    color: view.tinted ? _pillText : AppColors.mutedForeground,
                  ),
                ),
              ],
            ),
          ),
          if (action != null) ...[
            const SizedBox(width: 10),
            _Pill(
              label: action,
              busy: view.busy,
              onTap: () => ref
                  .read(placeCheckInControllerProvider(placeId).notifier)
                  .checkIn(),
            ),
          ],
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.icon, required this.tinted});

  final CheckInIcon icon;
  final bool tinted;

  @override
  Widget build(BuildContext context) {
    final check = icon == CheckInIcon.check;
    final filled = tinted;
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: filled
            ? AppColors.accent
            : check
            ? PlaceCheckInCard._tintBg
            : const Color(0xFFF4F4F5),
      ),
      child: Icon(
        switch (icon) {
          CheckInIcon.pin => Icons.place_outlined,
          CheckInIcon.check => Icons.check_rounded,
          CheckInIcon.signal => Icons.signal_cellular_alt_rounded,
          CheckInIcon.clock => Icons.schedule_rounded,
          CheckInIcon.locationOff => Icons.location_off_outlined,
        },
        size: 18,
        color: filled
            ? Colors.white
            : check
            ? AppColors.accent
            : AppColors.mutedForeground,
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.busy, required this.onTap});

  final String label;
  final bool busy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = busy ? AppColors.mutedForeground : PlaceCheckInCard._pillText;
    return Material(
      color: Colors.white,
      shape: StadiumBorder(
        side: BorderSide(
          width: 1.5,
          color: busy ? AppColors.cardBorder : PlaceCheckInCard._pillBorder,
        ),
      ),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: busy ? null : onTap,
        child: Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 13),
          alignment: Alignment.center,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (busy)
                SizedBox.square(
                  dimension: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.accent,
                  ),
                )
              else if (label == "I'm here")
                Icon(Icons.place_outlined, size: 16, color: AppColors.accent),
              if (busy || label == "I'm here") const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontFamily: AppTypeScale.family,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
