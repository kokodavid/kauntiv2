part of 'needs_connection.dart';

/// The tile and row forms of [NeedsConnection].
class _Tile extends StatelessWidget {
  const _Tile({
    required this.title,
    required this.checking,
    required this.onRetry,
  });

  final String title;
  final bool checking;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 148,
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.cardBorder),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _Circle(size: 32, icon: 16),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              height: 1.3,
              fontWeight: FontWeight.w600,
              color: AppColors.buttonForeground,
            ),
          ),
          if (onRetry != null) ...[
            const Spacer(),
            _RetryButton(checking: checking, onRetry: onRetry!, fontSize: 13),
          ],
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.title,
    required this.checking,
    required this.onRetry,
  });

  final String title;
  final bool checking;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 6, 6, 6),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.cardBorder),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.cloud_off_rounded,
            size: 16,
            color: AppColors.mutedForeground,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 12.5,
                height: 1.3,
                fontWeight: FontWeight.w500,
                color: AppColors.toastNeutralIcon,
              ),
            ),
          ),
          if (onRetry != null)
            Semantics(
              button: true,
              label: 'Retry',
              child: GestureDetector(
                onTap: checking ? null : onRetry,
                behavior: HitTestBehavior.opaque,
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    color: AppColors.offlineIconCircle,
                    shape: BoxShape.circle,
                  ),
                  child: checking
                      ? const Padding(
                          padding: EdgeInsets.all(14),
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(
                          Icons.refresh_rounded,
                          size: 18,
                          color: AppColors.buttonForeground,
                        ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
