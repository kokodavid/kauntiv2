import 'dart:async';

import 'package:flutter/material.dart';

import '../../../counties/county_paths.dart';
import '../../../design/app_colors.dart';
import '../../../widgets/county_picker_sheet.dart';

/// The "Home county" row in Edit Profile: shows the current home and opens
/// the county search to pick another. The pick is only held by the sheet;
/// it is saved with the rest when Save is tapped.
class EditProfileHomeCounty extends StatelessWidget {
  const EditProfileHomeCounty({
    super.key,
    required this.county,
    required this.onChanged,
  });

  final CountyPath? county;
  final ValueChanged<CountyPath> onChanged;

  Future<void> _pick(BuildContext context) async {
    final picked = await CountyPickerSheet.show(
      context,
      selectedCounty: county,
      title: 'Choose your home county',
    );
    if (picked != null) onChanged(picked);
  }

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: 'Home county, ${county?.name ?? 'not set'}. Change',
    excludeSemantics: true,
    onTap: () => unawaited(_pick(context)),
    child: InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => unawaited(_pick(context)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            const Icon(
              Icons.home_outlined,
              size: 20,
              color: AppColors.mutedForeground,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Home county',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    county?.name ?? 'Not set',
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: AppColors.mutedForeground,
                    ),
                  ),
                ],
              ),
            ),
            const Text(
              'Change',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.accent,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
