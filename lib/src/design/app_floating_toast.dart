import 'dart:async';

import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_text_styles.dart';

/// Tone for [showAppToast], matching the Claude-Design "01 · TOAST"
/// reference ("Dark, floating, one line where possible"): a dark pill
/// with a tinted icon circle, title, optional one-line subtitle, and an
/// optional trailing pill action. Each tone picks its own icon, icon
/// colour and how long it stays up by default - [success]/[warning]
/// close themselves after 4s, [neutral] (e.g. "Trip deleted · Undo")
/// stays 6s so there's time to act, and [error] stays until the user
/// dismisses it or taps its action, per this app's rule that errors
/// never disappear on their own.
enum AppToastVariant { success, error, warning, neutral }

IconData _defaultIcon(AppToastVariant variant) => switch (variant) {
  AppToastVariant.success => Icons.check,
  AppToastVariant.error => Icons.priority_high,
  AppToastVariant.warning => Icons.wifi_off,
  AppToastVariant.neutral => Icons.delete_outline,
};

Color _iconColor(AppToastVariant variant) => switch (variant) {
  AppToastVariant.success => AppColors.toastSuccessIcon,
  AppToastVariant.error => AppColors.danger,
  AppToastVariant.warning => AppColors.toastWarningIcon,
  AppToastVariant.neutral => AppColors.toastNeutralIcon,
};

Duration? _defaultDuration(AppToastVariant variant) => switch (variant) {
  AppToastVariant.success => const Duration(seconds: 4),
  AppToastVariant.warning => const Duration(seconds: 4),
  AppToastVariant.neutral => const Duration(seconds: 6),
  AppToastVariant.error => null,
};

/// The toast currently on screen, if any - so a new one replaces it
/// outright instead of stacking, per the design system's "one at a time;
/// a new one replaces the old" rule.
GlobalKey<_FloatingToastState>? _activeToastKey;

/// Shows the dark floating toast matching the Claude-Design "01 · TOAST"
/// reference. Use this in place of a [SnackBar] for anything that fits
/// one short line - [variant] alone decides the icon, its colour and how
/// long the toast stays up unless [duration] overrides it (`null` means
/// "stays until dismissed").
void showAppToast(
  BuildContext context, {
  required AppToastVariant variant,
  required String title,
  String? message,
  IconData? icon,
  String? actionLabel,
  VoidCallback? onAction,
  Duration? duration,
}) {
  // Replace whatever's already up - no ceremony, it's about to be
  // covered by the new one anyway.
  _activeToastKey?.currentState?.removeImmediately();
  _activeToastKey = null;

  // rootOverlay: true - same reasoning as this app's sheets and the "..."
  // menu popover - so the toast floats above AppShell's bottom nav bar
  // instead of ending up underneath it.
  final overlay = Overlay.of(context, rootOverlay: true);
  final key = GlobalKey<_FloatingToastState>();
  late final OverlayEntry entry;
  entry = OverlayEntry(
    builder: (context) => _FloatingToast(
      key: key,
      variant: variant,
      title: title,
      message: message,
      icon: icon ?? _defaultIcon(variant),
      actionLabel: actionLabel,
      onAction: onAction,
      duration: duration ?? _defaultDuration(variant),
      onRemove: () {
        if (_activeToastKey == key) _activeToastKey = null;
        entry.remove();
      },
    ),
  );
  _activeToastKey = key;
  overlay.insert(entry);
}

class _FloatingToast extends StatefulWidget {
  const _FloatingToast({
    required super.key,
    required this.variant,
    required this.title,
    required this.message,
    required this.icon,
    required this.actionLabel,
    required this.onAction,
    required this.duration,
    required this.onRemove,
  });

  final AppToastVariant variant;
  final String title;
  final String? message;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Duration? duration;
  final VoidCallback onRemove;

  @override
  State<_FloatingToast> createState() => _FloatingToastState();
}

class _FloatingToastState extends State<_FloatingToast>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 220),
    reverseDuration: const Duration(milliseconds: 160),
  );
  Timer? _timer;
  bool _removed = false;

  @override
  void initState() {
    super.initState();
    _controller.forward();
    final duration = widget.duration;
    if (duration != null) {
      _timer = Timer(duration, _close);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _close() {
    if (_removed) return;
    _timer?.cancel();
    _controller.reverse().whenComplete(() {
      if (!_removed) {
        _removed = true;
        widget.onRemove();
      }
    });
  }

  /// Used only when a new toast is about to replace this one - skips the
  /// close animation since this toast is being covered immediately.
  void removeImmediately() {
    if (_removed) return;
    _removed = true;
    _timer?.cancel();
    widget.onRemove();
  }

  void _handleAction() {
    widget.onAction?.call();
    _close();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final curved = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeIn,
    );
    return Positioned(
      left: 16,
      right: 16,
      // 96 matches JourneyActiveBanner's own offset above AppBottomNav,
      // so a toast never lands behind the floating tab bar.
      bottom: 96 + bottomInset,
      child: IgnorePointer(
        ignoring: _removed,
        child: AnimatedBuilder(
          animation: curved,
          builder: (context, child) => Opacity(
            opacity: curved.value.clamp(0, 1),
            child: Transform.translate(
              offset: Offset(0, 16 * (1 - curved.value)),
              child: child,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
              decoration: BoxDecoration(
                color: AppColors.toastBackground,
                borderRadius: BorderRadius.circular(18),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x33000000),
                    blurRadius: 24,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Tapping the icon/text (but not the action button below)
                  // dismisses the toast - the only way to clear an [error]
                  // toast, which otherwise stays until its action is used.
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: _close,
                      child: Row(
                        children: [
                          Container(
                            width: 30,
                            height: 30,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: _iconColor(widget.variant),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              widget.icon,
                              size: 16,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTextStyles.floatingToastTitle,
                                ),
                                if (widget.message != null)
                                  Text(
                                    widget.message!,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTextStyles.floatingToastMessage,
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (widget.actionLabel != null) ...[
                    const SizedBox(width: 8),
                    SizedBox(
                      height: 36,
                      child: TextButton(
                        onPressed: _handleAction,
                        style: TextButton.styleFrom(
                          backgroundColor: AppColors.toastActionBackground,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          shape: const StadiumBorder(),
                        ),
                        child: Text(
                          widget.actionLabel!,
                          style: AppTextStyles.toastActionLabel,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
