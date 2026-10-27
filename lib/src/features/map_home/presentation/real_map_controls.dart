import 'package:flutter/material.dart';

import '../../../design/app_colors.dart';
import 'real_map_layers.dart';
import 'real_map_style_pill.dart';

/// Compact controls for the embedded real map, in the top-right: the style
/// picker (a pill of Light / Terrain / Satellite that slides out to the left
/// of the layers button), 3D terrain, locate me.
class RealMapSideControls extends StatefulWidget {
  const RealMapSideControls({
    super.key,
    required this.top,
    required this.baseStyle,
    required this.onBaseStyleChanged,
    required this.terrainEnabled,
    required this.onTerrainChanged,
    required this.onLocate,
  });

  /// Distance from the top of the map slot.
  final double top;
  final RealMapBaseStyle baseStyle;
  final ValueChanged<RealMapBaseStyle> onBaseStyleChanged;
  final bool terrainEnabled;
  final ValueChanged<bool> onTerrainChanged;
  final VoidCallback onLocate;

  @override
  State<RealMapSideControls> createState() => _RealMapSideControlsState();
}

class _RealMapSideControlsState extends State<RealMapSideControls> {
  bool _pickerOpen = false;

  void _pick(RealMapBaseStyle style) {
    setState(() => _pickerOpen = false);
    widget.onBaseStyleChanged(style);
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: widget.top,
      left: 16,
      right: 16,
      child: Align(
        alignment: Alignment.topRight,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Flexible(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: SizeTransition(
                    sizeFactor: animation,
                    axis: Axis.horizontal,
                    axisAlignment: 1,
                    child: child,
                  ),
                ),
                child: _pickerOpen
                    ? Padding(
                        key: const ValueKey('picker'),
                        padding: const EdgeInsets.only(right: 8),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: RealMapStylePill(
                            selected: widget.baseStyle,
                            onSelected: _pick,
                          ),
                        ),
                      )
                    : const SizedBox.shrink(key: ValueKey('closed')),
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Semantics(
                  button: true,
                  label: 'Map style',
                  child: InkResponse(
                    onTap: () => setState(() => _pickerOpen = !_pickerOpen),
                    radius: 24,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Color(0x26000000),
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.layers_outlined,
                        size: 20,
                        color: _pickerOpen
                            ? AppColors.accent
                            : AppColors.foreground,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                RealMapRoundButton(
                  icon: Icons.terrain,
                  tooltip: widget.terrainEnabled ? '3D on' : '3D off',
                  active: widget.terrainEnabled,
                  onPressed: () =>
                      widget.onTerrainChanged(!widget.terrainEnabled),
                ),
                const SizedBox(height: 8),
                RealMapRoundButton(
                  icon: Icons.my_location,
                  tooltip: 'Show where I am',
                  onPressed: widget.onLocate,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Dark round map button; [active] fills it with the accent colour.
class RealMapRoundButton extends StatelessWidget {
  const RealMapRoundButton({
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
