import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../design/app_colors.dart';
import '../domain/connectivity_state.dart';
import '../services/connectivity_provider.dart';

part 'needs_connection_compact.dart';

/// How much room a [NeedsConnection] notice takes.
enum NeedsConnectionSize {
  /// The section's own slot, at its normal width.
  full,

  /// A carousel tile.
  tile,

  /// A narrow list card or sheet row.
  row,
}

/// Stands in for a section that needs the internet (Offline States 02).
/// Wrap the section: online it renders [child]; offline it renders the
/// notice, so screens don't branch by hand. Retry rechecks the connection.
class NeedsConnection extends ConsumerWidget {
  const NeedsConnection({
    super.key,
    required this.child,
    this.size = NeedsConnectionSize.full,
    this.title = 'Needs a connection',
    this.message,
    this.showRetry = true,
    this.onRetry,
  });

  final Widget child;
  final NeedsConnectionSize size;
  final String title;

  /// What's missing, in one sentence ("Unclaimed counties load from the
  /// internet."). Full size only.
  final String? message;

  /// False when the banner already covers it.
  final bool showRetry;

  /// Also called when Retry is tapped, after the connection recheck.
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(connectivityProvider);
    if (!state.isOffline) return child;
    final checking = state.status == ConnectivityStatus.checking;
    void retry() {
      onRetry?.call();
      ref.read(connectivityProvider.notifier).recheck();
    }

    return switch (size) {
      NeedsConnectionSize.full => _Full(
        title: title,
        message: message,
        showRetry: showRetry,
        checking: checking,
        onRetry: retry,
      ),
      NeedsConnectionSize.tile => _Tile(
        title: title,
        checking: checking,
        onRetry: showRetry ? retry : null,
      ),
      NeedsConnectionSize.row => _Row(
        title: title,
        checking: checking,
        onRetry: showRetry ? retry : null,
      ),
    };
  }
}

class _Circle extends StatelessWidget {
  const _Circle({required this.size, required this.icon});

  final double size;
  final double icon;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: const BoxDecoration(
      color: AppColors.offlineIconCircle,
      shape: BoxShape.circle,
    ),
    child: Icon(
      Icons.cloud_off_rounded,
      size: icon,
      color: AppColors.mutedForeground,
    ),
  );
}

class _RetryButton extends StatelessWidget {
  const _RetryButton({
    required this.checking,
    required this.onRetry,
    this.fontSize = 14,
    this.fullWidth = true,
  });

  final bool checking;
  final VoidCallback onRetry;
  final double fontSize;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: fullWidth ? double.infinity : null,
      height: 44,
      child: OutlinedButton(
        onPressed: checking ? null : onRetry,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.buttonForeground,
          disabledForegroundColor: AppColors.mutedForeground,
          side: const BorderSide(color: AppColors.cardBorder),
          shape: const StadiumBorder(),
          textStyle: TextStyle(fontSize: fontSize, fontWeight: FontWeight.w600),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (checking)
              const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              const Icon(Icons.refresh_rounded, size: 16),
            const SizedBox(width: 8),
            Text(checking ? 'Checking…' : 'Retry'),
          ],
        ),
      ),
    );
  }
}

class _Full extends StatelessWidget {
  const _Full({
    required this.title,
    required this.message,
    required this.showRetry,
    required this.checking,
    required this.onRetry,
  });

  final String title;
  final String? message;
  final bool showRetry;
  final bool checking;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.cardBorder),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _Circle(size: 40, icon: 18),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.buttonForeground,
                      ),
                    ),
                    if (message != null) ...[
                      const SizedBox(height: 3),
                      Text(
                        message!,
                        style: const TextStyle(
                          fontSize: 13,
                          height: 1.45,
                          color: AppColors.mutedForeground,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          if (showRetry) ...[
            const SizedBox(height: 14),
            _RetryButton(checking: checking, onRetry: onRetry),
          ],
        ],
      ),
    );
  }
}
