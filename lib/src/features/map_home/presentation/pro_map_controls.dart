import 'package:flutter/material.dart';

import '../../../design/app_colors.dart';
import 'pro_map_layers.dart';

/// Bottom controls of the Pro map: base style picker and the 3D toggle.
class ProMapControls extends StatelessWidget {
  const ProMapControls({
    super.key,
    required this.baseStyle,
    required this.onBaseStyleChanged,
    required this.terrainEnabled,
    required this.onTerrainChanged,
  });

  final ProMapBaseStyle baseStyle;
  final ValueChanged<ProMapBaseStyle> onBaseStyleChanged;
  final bool terrainEnabled;
  final ValueChanged<bool> onTerrainChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SegmentedButton<ProMapBaseStyle>(
          segments: [
            for (final style in ProMapBaseStyle.values)
              ButtonSegment(value: style, label: Text(style.label)),
          ],
          selected: {baseStyle},
          showSelectedIcon: false,
          style: _segmentStyle,
          onSelectionChanged: (value) => onBaseStyleChanged(value.first),
        ),
        const SizedBox(width: 8),
        SegmentedButton<bool>(
          segments: const [
            ButtonSegment(
              value: true,
              label: Text('3D'),
              icon: Icon(Icons.terrain, size: 16),
            ),
          ],
          selected: {if (terrainEnabled) true},
          emptySelectionAllowed: true,
          showSelectedIcon: false,
          style: _segmentStyle,
          onSelectionChanged: (value) => onTerrainChanged(value.contains(true)),
        ),
      ],
    );
  }

  static final _segmentStyle = SegmentedButton.styleFrom(
    backgroundColor: Colors.white,
    selectedBackgroundColor: AppColors.accent,
    selectedForegroundColor: Colors.white,
  );
}
