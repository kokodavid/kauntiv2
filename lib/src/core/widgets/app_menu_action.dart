import 'package:flutter/material.dart';

/// One row in an [AppActionsMenuButton]'s popover.
class AppMenuAction {
  const AppMenuAction({
    required this.label,
    required this.icon,
    required this.onTap,
    this.isDestructive = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool isDestructive;
}
