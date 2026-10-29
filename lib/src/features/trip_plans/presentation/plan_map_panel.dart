import 'package:flutter/material.dart';

import '../../../core/design/app_type_scale.dart';
import '../../../design/app_colors.dart';
import '../domain/plan_route.dart';
import 'plan_map.dart';

/// The plan screen's map (design 3a): 240 high, or a 56 strip when folded
/// away, with a button to open it full screen.
class PlanMapPanel extends StatelessWidget {
  const PlanMapPanel({
    super.key,
    required this.days,
    required this.activeDay,
    required this.open,
    required this.onToggle,
  });

  final List<PlanMapDay> days;
  final int? activeDay;
  final bool open;
  final VoidCallback onToggle;

  static const openHeight = 240.0;
  static const stripHeight = 56.0;

  @override
  Widget build(BuildContext context) {
    if (!open) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Material(
          color: AppColors.exploreSurface,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onToggle,
            child: Container(
              height: stripHeight,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.exploreBorder),
              ),
              child: const Row(
                children: [
                  Icon(Icons.map_outlined, size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text('Show map', style: AppTypeScale.itemTitle),
                  ),
                  Icon(Icons.expand_more),
                ],
              ),
            ),
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: SizedBox(
          height: openHeight,
          child: Stack(
            fit: StackFit.expand,
            children: [
              PlanMap(days: days, activeDay: activeDay),
              Positioned(
                top: 6,
                right: 6,
                child: Column(
                  children: [
                    _RoundButton(
                      tooltip: 'Full screen map',
                      icon: Icons.fullscreen,
                      onPressed: () => Navigator.of(context).push<void>(
                        MaterialPageRoute(
                          fullscreenDialog: true,
                          builder: (_) =>
                              PlanMapPage(days: days, activeDay: activeDay),
                        ),
                      ),
                    ),
                    _RoundButton(
                      tooltip: 'Hide map',
                      icon: Icons.expand_less,
                      onPressed: onToggle,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 1,
      child: IconButton(
        tooltip: tooltip,
        constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
        onPressed: onPressed,
        icon: Icon(icon, size: 22),
      ),
    ),
  );
}

/// The map on its own screen, for a closer look.
class PlanMapPage extends StatelessWidget {
  const PlanMapPage({super.key, required this.days, this.activeDay});

  final List<PlanMapDay> days;
  final int? activeDay;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Stack(
      fit: StackFit.expand,
      children: [
        PlanMap(
          days: days,
          activeDay: activeDay,
          padding: const EdgeInsets.fromLTRB(32, 96, 32, 48),
        ),
        SafeArea(
          child: Align(
            alignment: Alignment.topLeft,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Material(
                color: Colors.white,
                shape: const CircleBorder(),
                elevation: 1,
                child: IconButton(
                  tooltip: 'Close map',
                  constraints: const BoxConstraints(
                    minWidth: 44,
                    minHeight: 44,
                  ),
                  onPressed: () => Navigator.of(context).maybePop(),
                  icon: const Icon(Icons.close),
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
