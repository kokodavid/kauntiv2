part of 'trip_share_sheet.dart';

class _TripShareActionRow extends StatelessWidget {
  const _TripShareActionRow({
    required this.buttonKey,
    required this.saving,
    required this.sharing,
    required this.sharingInstagram,
    required this.instagramAvailable,
    required this.onSave,
    required this.onShareInstagram,
    required this.onShare,
  });

  final Key buttonKey;
  final bool saving;
  final bool sharing;
  final bool sharingInstagram;
  final bool instagramAvailable;
  final VoidCallback onSave;
  final VoidCallback onShareInstagram;
  final VoidCallback onShare;

  bool get _busy => saving || sharing || sharingInstagram;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      SizedBox(
        width: 52,
        height: 52,
        child: OutlinedButton(
          onPressed: _busy ? null : onSave,
          style: OutlinedButton.styleFrom(
            backgroundColor: AppColors.lockedFill,
            foregroundColor: AppColors.buttonForeground,
            side: BorderSide.none,
            shape: const CircleBorder(),
            padding: EdgeInsets.zero,
          ),
          child: saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const AppGlyphIcon(
                  path: AppGlyphPaths.download,
                  size: 20,
                  color: AppColors.buttonForeground,
                ),
        ),
      ),
      const SizedBox(width: 10),
      if (instagramAvailable) ...[
        SizedBox(
          width: 52,
          height: 52,
          child: OutlinedButton(
            onPressed: _busy ? null : onShareInstagram,
            style: OutlinedButton.styleFrom(
              backgroundColor: AppColors.lockedFill,
              foregroundColor: AppColors.buttonForeground,
              side: BorderSide.none,
              shape: const CircleBorder(),
              padding: EdgeInsets.zero,
            ),
            child: sharingInstagram
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(
                    Icons.camera_alt_rounded,
                    size: 20,
                    color: AppColors.buttonForeground,
                  ),
          ),
        ),
        const SizedBox(width: 10),
      ],
      Expanded(
        child: SizedBox(
          key: buttonKey,
          height: 52,
          child: ElevatedButton.icon(
            onPressed: _busy ? null : onShare,
            icon: sharing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const AppGlyphIcon(
                    path: AppGlyphPaths.share,
                    size: 18,
                    color: Colors.white,
                  ),
            label: Text(
              sharing ? 'Preparing…' : 'Share',
              style: AppTextStyles.confirmSheetButtonLabel,
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: Colors.white,
              disabledBackgroundColor: AppColors.accent,
              elevation: 0,
              shape: const StadiumBorder(),
            ),
          ),
        ),
      ),
    ],
  );
}
