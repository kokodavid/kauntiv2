import 'package:flutter/material.dart';

import '../../../core/design/app_type_scale.dart';
import '../../../design/app_colors.dart';

/// My photos before the user has sent anything.
class MyPhotosEmpty extends StatelessWidget {
  const MyPhotosEmpty({super.key});

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(40, 0, 40, 120),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        spacing: 10,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: const Icon(
              Icons.photo_library_outlined,
              color: AppColors.mutedForeground,
            ),
          ),
          const Text(
            "You haven't sent any photos yet",
            textAlign: TextAlign.center,
            style: AppTypeScale.sectionTitle,
          ),
          const Text(
            'Been somewhere on Kaunti47? Open the place and tap Add photo '
            'under Photos.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: AppTypeScale.family,
              fontSize: 13,
              height: 1.5,
              color: AppColors.mutedForeground,
            ),
          ),
        ],
      ),
    ),
  );
}
