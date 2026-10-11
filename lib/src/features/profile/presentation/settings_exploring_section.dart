import 'package:flutter/material.dart';

import '../domain/place_interest.dart';
import 'settings_widgets.dart';

/// Settings > Exploring: what shapes For you. Today just Interests, which
/// reads "Not set" until the setup question is answered.
class SettingsExploringSection extends StatelessWidget {
  const SettingsExploringSection({
    super.key,
    required this.interests,
    required this.onOpenInterests,
  });

  final List<PlaceInterest> interests;
  final VoidCallback onOpenInterests;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SettingsSectionLabel('Exploring'),
        SettingsCard(
          children: [
            SettingsActionRow(
              title: 'Interests',
              subtitle: interestsSummary(interests),
              onTap: onOpenInterests,
            ),
          ],
        ),
      ],
    );
  }
}
