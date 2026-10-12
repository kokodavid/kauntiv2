import 'package:flutter/material.dart';

import 'real_map_controls.dart';

/// The round button on Home's right edge that swaps between the live map
/// and the simple drawn map. It sits above both map layers, so the user can
/// always get back to whichever one they are not viewing.
class MapHomeMapSwitchButton extends StatelessWidget {
  const MapHomeMapSwitchButton({
    super.key,
    required this.top,
    required this.preferDrawnMap,
    required this.onToggle,
  });

  final double top;
  final bool preferDrawnMap;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) => Positioned(
    top: top,
    right: 16,
    child: RealMapRoundButton(
      icon: preferDrawnMap ? Icons.public : Icons.map_outlined,
      tooltip: preferDrawnMap ? 'Switch to live map' : 'Switch to simple map',
      active: preferDrawnMap,
      onPressed: onToggle,
    ),
  );
}
