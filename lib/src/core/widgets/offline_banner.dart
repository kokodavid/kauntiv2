import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../design/app_colors.dart';
import '../domain/connectivity_state.dart';
import '../domain/saved_at_label.dart';
import '../services/connectivity_provider.dart';
import '../services/offline_saved_at.dart';
import '../services/offline_screen_presence.dart';

/// The app-wide offline pill (Offline States 01/04). Mounted once in the
/// shell. It reads [connectivityProvider]: nothing shows it by hand.
///
/// Offline: "You're offline. Some things are unavailable." When a screen is
/// showing a saved copy it reads "You're offline · Saved 9:41 AM" with a
/// Retry. Then "Checking connection...", "Back online · updating...", "Up
/// to date", and out. It enters after the provider's 1.5 s confirmation,
/// sliding 12 px over 280 ms; it leaves in 220 ms.
class OfflineBanner extends ConsumerStatefulWidget {
  const OfflineBanner({super.key});

  /// The room the pill takes at the top of the page.
  static const height = 44.0;

  @override
  ConsumerState<OfflineBanner> createState() => _OfflineBannerState();
}

class _OfflineBannerState extends ConsumerState<OfflineBanner> {
  // Keeps the last visible content on screen while the pill fades out.
  ConnectivityStatus _shown = ConnectivityStatus.offline;

  @override
  Widget build(BuildContext context) {
    final status = ref.watch(connectivityProvider.select((s) => s.status));
    final savedAt = ref.watch(offlineSavedAtProvider);
    // A full-screen "You're offline" says it already; don't say it twice.
    final suppressed = ref.watch(offlineBannerSuppressedProvider);
    final visible = status != ConnectivityStatus.online && !suppressed;
    if (visible) _shown = status;
    final content = _shown;
    return IgnorePointer(
      ignoring: !visible,
      child: AnimatedSlide(
        offset: visible ? Offset.zero : const Offset(0, -0.3),
        duration: Duration(milliseconds: visible ? 280 : 220),
        curve: visible ? Curves.easeOutCubic : Curves.easeIn,
        child: AnimatedOpacity(
          opacity: visible ? 1 : 0,
          duration: Duration(milliseconds: visible ? 280 : 220),
          child: Center(
            child: _Pill(
              status: content,
              savedAt: savedAt,
              onRetry: () => ref.read(connectivityProvider.notifier).recheck(),
            ),
          ),
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.status,
    required this.savedAt,
    required this.onRetry,
  });

  final ConnectivityStatus status;
  final DateTime? savedAt;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final offline = status == ConnectivityStatus.offline;
    final saved = savedAtLabel(savedAt, DateTime.now(), verboseToday: false);
    final text = switch (status) {
      ConnectivityStatus.offline =>
        saved == null
            ? "You're offline. Some things are unavailable."
            : "You're offline · $saved",
      ConnectivityStatus.checking => 'Checking connection…',
      ConnectivityStatus.reconnecting => 'Back online · updating…',
      _ => 'Up to date',
    };
    final retry = offline && saved != null;
    return AnimatedSize(
      duration: const Duration(milliseconds: 160),
      child: Container(
        height: 40,
        padding: EdgeInsets.only(left: 14, right: retry ? 4 : 14),
        decoration: BoxDecoration(
          color: AppColors.offlinePillBackground,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x2E000000),
              blurRadius: 18,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 160),
              child: _Icon(key: ValueKey(status), status: status),
            ),
            const SizedBox(width: 10),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 160),
              child: Text(
                text,
                key: ValueKey(text),
                maxLines: 1,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (retry) ...[
              const SizedBox(width: 10),
              Semantics(
                button: true,
                label: 'Retry',
                child: GestureDetector(
                  onTap: onRetry,
                  behavior: HitTestBehavior.opaque,
                  child: SizedBox(
                    height: 44,
                    child: Center(
                      child: Container(
                        height: 30,
                        padding: const EdgeInsets.symmetric(horizontal: 11),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const Text(
                          'Retry',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Icon extends StatelessWidget {
  const _Icon({super.key, required this.status});

  final ConnectivityStatus status;

  @override
  Widget build(BuildContext context) {
    return switch (status) {
      ConnectivityStatus.checking => const SizedBox(
        width: 16,
        height: 16,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: Colors.white,
          backgroundColor: Color(0x33FFFFFF),
        ),
      ),
      ConnectivityStatus.reconnecting => const Icon(
        Icons.wifi_rounded,
        size: 16,
        color: AppColors.offlinePillBackOnline,
      ),
      ConnectivityStatus.upToDate => const Icon(
        Icons.check_rounded,
        size: 16,
        color: AppColors.offlinePillBackOnline,
      ),
      _ => const Icon(
        Icons.cloud_off_rounded,
        size: 16,
        color: AppColors.offlinePillIcon,
      ),
    };
  }
}
