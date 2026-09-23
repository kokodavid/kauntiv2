import 'package:flutter/material.dart';

import '../../../design/app_colors.dart';
import 'pro_map_layers.dart';

/// Compact controls for the embedded Pro map, stacked on the right of the
/// map slot: base style, 3D terrain, locate me.
class ProMapSideControls extends StatelessWidget {
  const ProMapSideControls({
    super.key,
    required this.baseStyle,
    required this.onBaseStyleChanged,
    required this.terrainEnabled,
    required this.onTerrainChanged,
    required this.onLocate,
  });

  final ProMapBaseStyle baseStyle;
  final ValueChanged<ProMapBaseStyle> onBaseStyleChanged;
  final bool terrainEnabled;
  final ValueChanged<bool> onTerrainChanged;
  final VoidCallback onLocate;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        PopupMenuButton<ProMapBaseStyle>(
          tooltip: 'Map style',
          initialValue: baseStyle,
          onSelected: onBaseStyleChanged,
          itemBuilder: (context) => [
            for (final style in ProMapBaseStyle.values)
              CheckedPopupMenuItem(
                value: style,
                checked: style == baseStyle,
                child: Text(style.label),
              ),
          ],
          child: const _RoundIcon(icon: Icons.layers_outlined),
        ),
        const SizedBox(height: 8),
        ProMapRoundButton(
          icon: Icons.terrain,
          tooltip: terrainEnabled ? '3D on' : '3D off',
          active: terrainEnabled,
          onPressed: () => onTerrainChanged(!terrainEnabled),
        ),
        const SizedBox(height: 8),
        ProMapRoundButton(
          icon: Icons.my_location,
          tooltip: 'Show where I am',
          onPressed: onLocate,
        ),
      ],
    );
  }
}

/// Dark round map button; [active] fills it with the accent colour.
class ProMapRoundButton extends StatelessWidget {
  const ProMapRoundButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.tooltip,
    this.active = false,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final String? tooltip;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip ?? '',
      child: InkResponse(
        onTap: onPressed,
        radius: 24,
        child: _RoundIcon(icon: icon, active: active),
      ),
    );
  }
}

class _RoundIcon extends StatelessWidget {
  const _RoundIcon({required this.icon, this.active = false});

  final IconData icon;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: active ? AppColors.accent : AppColors.mapOverlayBackground,
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: 20, color: AppColors.mapOverlayForeground),
    );
  }
}
