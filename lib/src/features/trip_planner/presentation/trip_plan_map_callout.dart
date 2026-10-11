import 'package:flutter/material.dart';

import '../../../core/design/app_type_scale.dart';
import '../../../design/app_colors.dart';

/// The dark label above the selected pin: the stop's name and county.
class TripPlanMapCallout extends StatelessWidget {
  const TripPlanMapCallout({super.key, required this.title, this.subtitle});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            constraints: const BoxConstraints(maxWidth: 220),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.toastBackground,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypeScale.itemTitle.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypeScale.small.copyWith(
                      color: AppColors.toastSubtitle,
                    ),
                  ),
              ],
            ),
          ),
          Transform.rotate(
            angle: 0.785398,
            child: Transform.translate(
              offset: const Offset(0, -6),
              child: Container(
                width: 12,
                height: 12,
                color: AppColors.toastBackground,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
