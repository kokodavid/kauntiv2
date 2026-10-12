import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../design/app_colors.dart';
import '../domain/connectivity_state.dart';
import '../services/connectivity_provider.dart';
import '../services/offline_screen_presence.dart';
import 'offline_hint.dart';

/// Where an [OfflineScreen] sits.
enum OfflineScreenLayout {
  /// Fills a page body (Offline States 06, default).
  page,

  /// Sits at the bottom of a sheet: smaller icon, full-width button.
  sheet,
}

/// What went wrong, which swaps the copy.
enum OfflineScreenKind {
  /// The phone has no connection.
  offline,

  /// The phone is online but the server failed.
  serverError,
}

/// The state for a screen that can't load at all (Offline States 06): used
/// only when there is nothing saved to show, in place of the body, with the
/// app bar and Back left alone.
///
/// Reads [connectivityProvider]: nothing picks the kind by hand. Offline it
/// says "You're offline"; online (the load failed anyway) it says "Couldn't
/// load this page". Try again rechecks, then calls [onRetry]; and the
/// moment the connection returns [onRetry] runs by itself so the screen
/// loads without a tap. While it shows, the global banner steps aside.
class OfflineScreen extends ConsumerStatefulWidget {
  const OfflineScreen({
    super.key,
    required this.onRetry,
    this.layout = OfflineScreenLayout.page,
    this.message,
    this.serverMessage,
    this.showHint = true,
  });

  final VoidCallback onRetry;
  final OfflineScreenLayout layout;

  /// Offline copy; defaults to "This page needs a connection. Check your
  /// data or Wi-Fi, then try again." A sheet passes "Nakuru needs a
  /// connection to load.".
  final String? message;

  /// Online-but-failed copy.
  final String? serverMessage;

  /// The green-tick "Counties you visit are still saved." line (page only).
  final bool showHint;

  @override
  ConsumerState<OfflineScreen> createState() => _OfflineScreenState();
}

class _OfflineScreenState extends ConsumerState<OfflineScreen> {
  late final OfflineScreenPresence _presence;

  @override
  void initState() {
    super.initState();
    _presence = ref.read(offlineScreenPresenceProvider.notifier);
    // Not during build: providers can't change while the tree is building.
    unawaited(Future.microtask(_presence.enter));
  }

  @override
  void dispose() {
    unawaited(Future.microtask(_presence.leave));
    super.dispose();
  }

  void _retry() {
    unawaited(() async {
      await ref.read(connectivityProvider.notifier).recheck();
      if (mounted) widget.onRetry();
    }());
  }

  @override
  Widget build(BuildContext context) {
    // Back online: load by itself; Try again is only a shortcut.
    ref.listen(connectivityProvider.select((s) => s.isOffline), (was, now) {
      if (was == true && !now) widget.onRetry();
    });
    final state = ref.watch(connectivityProvider);
    final kind = state.isOffline
        ? OfflineScreenKind.offline
        : OfflineScreenKind.serverError;
    final checking = state.status == ConnectivityStatus.checking;
    final sheet = widget.layout == OfflineScreenLayout.sheet;
    final offline = kind == OfflineScreenKind.offline;
    final title = offline ? "You're offline" : "Couldn't load this page";
    final message = offline
        ? widget.message ??
              'This page needs a connection. Check your data or Wi‑Fi, '
                  'then try again.'
        : widget.serverMessage ??
              'Something went wrong on our side. Try again in a moment.';
    final body = _Body(
      sheet: sheet,
      title: title,
      message: message,
      checking: checking,
      showHint: widget.showHint && offline && !sheet,
      onRetry: _retry,
    );
    if (sheet) return body;
    return Center(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(28, 0, 28, 120),
        child: body,
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({
    required this.sheet,
    required this.title,
    required this.message,
    required this.checking,
    required this.showHint,
    required this.onRetry,
  });

  final bool sheet;
  final String title;
  final String message;
  final bool checking;
  final bool showHint;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final circle = sheet ? 56.0 : 72.0;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: circle,
          height: circle,
          decoration: BoxDecoration(
            color: sheet ? AppColors.offlineIconCircle : Colors.white,
            shape: BoxShape.circle,
            border: sheet ? null : Border.all(color: AppColors.cardBorder),
          ),
          child: Icon(
            Icons.cloud_off_rounded,
            size: sheet ? 24 : 30,
            color: AppColors.mutedForeground,
          ),
        ),
        SizedBox(height: sheet ? 12 : 20),
        Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: sheet ? 18 : 22,
            fontWeight: FontWeight.w700,
            letterSpacing: sheet ? 0 : -0.44,
            color: AppColors.buttonForeground,
          ),
        ),
        SizedBox(height: sheet ? 4 : 8),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 290),
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: sheet ? 13.5 : 14.5,
              height: 1.5,
              color: AppColors.mutedForeground,
            ),
          ),
        ),
        SizedBox(height: sheet ? 16 : 24),
        _TryAgain(
          checking: checking,
          onPressed: onRetry,
          width: sheet ? double.infinity : 220,
          height: sheet ? 48 : 52,
        ),
        if (showHint) ...[
          const SizedBox(height: 22),
          const OfflineHintBody(text: 'Counties you visit are still saved.'),
        ],
      ],
    );
  }
}

class _TryAgain extends StatelessWidget {
  const _TryAgain({
    required this.checking,
    required this.onPressed,
    required this.width,
    required this.height,
  });

  final bool checking;
  final VoidCallback onPressed;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: width,
    height: height,
    child: FilledButton(
      onPressed: checking ? null : onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.accent,
        disabledBackgroundColor: AppColors.offlineScreenButtonChecking,
        foregroundColor: Colors.white,
        disabledForegroundColor: Colors.white,
        shape: const StadiumBorder(),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (checking) ...[
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Text(checking ? 'Checking…' : 'Try again'),
        ],
      ),
    ),
  );
}
