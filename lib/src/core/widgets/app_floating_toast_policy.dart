part of 'app_floating_toast.dart';

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

GlobalKey<_FloatingToastState>? _activeToastKey;
