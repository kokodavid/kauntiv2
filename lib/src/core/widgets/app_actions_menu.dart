import 'dart:async';

import 'package:flutter/material.dart';

import '../../design/app_colors.dart';
import '../../design/app_text_styles.dart';

/// One row in an [AppActionsMenuButton]'s popover - a label with a
/// leading icon, optionally styled red for a destructive action (Delete).
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

/// The "..." trigger and its popover menu, styled to the Claude-Design
/// "Menu" reference ("Popover from the ... button"): a 40x40 circular
/// trigger (tinted grey while open), opening a 212px-wide white popover
/// with rounded corners and a soft shadow, anchored just under the
/// trigger with its right edge aligned to it, scaling in from the
/// top-right corner. This is the first widget migrated to that design
/// system - every Trip "..." menu (card, tile, and anywhere else a
/// Rename/Delete popover shows up) should share this one rather than a
/// bespoke `PopupMenuButton`, so they look and animate identically.
class AppActionsMenuButton extends StatefulWidget {
  const AppActionsMenuButton({
    super.key,
    required this.actions,
    this.tooltip = 'More options',
  });

  final List<AppMenuAction> actions;
  final String tooltip;

  @override
  State<AppActionsMenuButton> createState() => _AppActionsMenuButtonState();
}

class _AppActionsMenuButtonState extends State<AppActionsMenuButton>
    with SingleTickerProviderStateMixin {
  final _link = LayerLink();

  // Built eagerly in initState(), not as a lazy `late final` initializer:
  // a menu that's scrolled away (a filtered-out Trip card, say) can be
  // disposed having never been tapped, so a lazy initializer would run
  // for the first time inside dispose() itself - by then this element
  // is already deactivated, and AnimationController's constructor needs
  // a live ancestor (TickerMode) to create its ticker, so that first
  // access threw "Looking up a deactivated widget's ancestor is
  // unsafe." Constructing it up front guarantees it already exists by
  // the time dispose() runs.
  late final AnimationController _controller;
  OverlayEntry? _entry;
  bool _open = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
      reverseDuration: const Duration(milliseconds: 140),
    );
  }

  @override
  void dispose() {
    _removeEntry();
    _controller.dispose();
    super.dispose();
  }

  void _removeEntry() {
    _entry?.remove();
    _entry = null;
  }

  void _toggle() {
    if (_open) {
      _close();
    } else {
      _show();
    }
  }

  void _show() {
    // rootOverlay: true - same reasoning as the useRootNavigator fix on
    // this app's modal sheets - so the popover sits above AppShell's
    // floating bottom nav bar instead of the active tab's own nested
    // Overlay, which paints underneath it.
    final overlay = Overlay.of(context, rootOverlay: true);
    _entry = OverlayEntry(
      builder: (context) => _ActionsMenuOverlay(
        link: _link,
        controller: _controller,
        actions: widget.actions,
        onSelected: (action) {
          _close();
          action.onTap();
        },
        onDismiss: _close,
      ),
    );
    overlay.insert(_entry!);
    setState(() => _open = true);
    unawaited(_controller.forward(from: 0));
  }

  void _close() {
    if (!_open) return;
    setState(() => _open = false);
    unawaited(_controller.reverse().whenComplete(_removeEntry));
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _link,
      child: SizedBox(
        width: 40,
        height: 40,
        child: Tooltip(
          message: widget.tooltip,
          child: Material(
            shape: const CircleBorder(),
            color: _open ? AppColors.menuButtonPressed : Colors.transparent,
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: _toggle,
              child: const Center(
                child: Icon(
                  Icons.more_horiz,
                  size: 18,
                  color: AppColors.mutedForeground,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The popover surface itself: a full-screen tap-to-dismiss barrier
/// behind a [CompositedTransformFollower] holding the rounded white menu,
/// fading and scaling in from its top-right corner.
class _ActionsMenuOverlay extends StatelessWidget {
  const _ActionsMenuOverlay({
    required this.link,
    required this.controller,
    required this.actions,
    required this.onSelected,
    required this.onDismiss,
  });

  final LayerLink link;
  final AnimationController controller;
  final List<AppMenuAction> actions;
  final ValueChanged<AppMenuAction> onSelected;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final curved = CurvedAnimation(
      parent: controller,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeIn,
    );
    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: onDismiss,
          ),
        ),
        CompositedTransformFollower(
          link: link,
          targetAnchor: Alignment.bottomRight,
          followerAnchor: Alignment.topRight,
          offset: const Offset(0, 8),
          child: Align(
            alignment: Alignment.topRight,
            child: AnimatedBuilder(
              animation: curved,
              builder: (context, child) {
                final t = curved.value;
                return Opacity(
                  opacity: t.clamp(0, 1),
                  child: Transform.translate(
                    offset: Offset(0, -4 * (1 - t)),
                    child: Transform.scale(
                      scale: 0.9 + (0.1 * t),
                      alignment: Alignment.topRight,
                      child: child,
                    ),
                  ),
                );
              },
              child: _ActionsMenuSurface(
                actions: actions,
                onSelected: onSelected,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ActionsMenuSurface extends StatelessWidget {
  const _ActionsMenuSurface({required this.actions, required this.onSelected});

  final List<AppMenuAction> actions;
  final ValueChanged<AppMenuAction> onSelected;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 0,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: 212,
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.cardBorder),
          boxShadow: const [
            BoxShadow(
              color: Color(0x24000000),
              blurRadius: 32,
              offset: Offset(0, 12),
            ),
            BoxShadow(
              color: Color(0x0F000000),
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final action in actions) ...[
              if (action != actions.first)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Divider(height: 1, color: AppColors.menuDivider),
                ),
              _ActionsMenuRow(action: action, onSelected: onSelected),
            ],
          ],
        ),
      ),
    );
  }
}

class _ActionsMenuRow extends StatelessWidget {
  const _ActionsMenuRow({required this.action, required this.onSelected});

  final AppMenuAction action;
  final ValueChanged<AppMenuAction> onSelected;

  @override
  Widget build(BuildContext context) {
    final color = action.isDestructive
        ? AppColors.danger
        : AppColors.buttonForeground;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        hoverColor: action.isDestructive
            ? AppColors.menuDangerItemPressed
            : AppColors.menuItemPressed,
        splashColor: action.isDestructive
            ? AppColors.menuDangerItemPressed
            : AppColors.menuItemPressed,
        highlightColor: action.isDestructive
            ? AppColors.menuDangerItemPressed
            : AppColors.menuItemPressed,
        onTap: () => onSelected(action),
        child: SizedBox(
          height: 46,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Icon(action.icon, size: 18, color: color),
                const SizedBox(width: 12),
                Text(
                  action.label,
                  style: AppTextStyles.menuItemLabel.copyWith(color: color),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
