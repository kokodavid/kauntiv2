import 'dart:async';

import 'package:flutter/material.dart';

import '../../../counties/county_paths.dart';
import '../../../design/app_colors.dart';
import '../../../widgets/app_county_map.dart';
import '../../../widgets/county_picker_sheet.dart';

/// The "Home county" row in Edit Profile: a small map of Kenya with the
/// home county highlighted, its name, and opens
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
            // Kenya with the home county lit up (same aspect as the map).
            SizedBox(
              width: 40,
              height: 40 * CountyPaths.viewBoxHeight / CountyPaths.viewBoxWidth,
              child: ExcludeSemantics(
                child: AppCountyMap(selectedCounty: county),
              ),
            ),
            const SizedBox(width: 14),
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
