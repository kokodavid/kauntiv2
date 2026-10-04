import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/app_back_button.dart';
import '../../../core/widgets/app_confirm_sheet.dart';
import '../../../core/widgets/app_floating_toast.dart';
import '../../../core/widgets/app_shimmer.dart';
import '../../../design/app_colors.dart';
import '../application/public_trip_viewer_providers.dart';
import '../domain/public_trip_failure.dart';
import '../domain/public_trip_view.dart';
import 'public_trip_replay.dart';
import 'public_trip_report_sheet.dart';
import 'public_trip_screen_body.dart';
import 'public_trip_unavailable.dart';

export 'public_trip_screen_body.dart' show OpenPublicTripDirections;

/// A public trip, read-only: the route and what its author chose to share.
/// It never records or follows the viewer. While open it re-checks the trip
/// is still shared, and falls back to a neutral state the moment it is not.
class PublicTripScreen extends ConsumerStatefulWidget {
  const PublicTripScreen({
    super.key,
    required this.publicationId,
    this.onOpenDirections,
  });

  final String publicationId;
  final OpenPublicTripDirections? onOpenDirections;

  @override
  ConsumerState<PublicTripScreen> createState() => _PublicTripScreenState();
}

class _PublicTripScreenState extends ConsumerState<PublicTripScreen>
    with WidgetsBindingObserver {
  Timer? _recheck;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startRecheck();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _recheck?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refresh();
      _startRecheck();
    } else {
      // Nothing is checked, or shown again, until the app is back.
      _recheck?.cancel();
    }
  }

  void _startRecheck() {
    _recheck?.cancel();
    _recheck = Timer.periodic(
      ref.read(publicTripAccessRecheckIntervalProvider),
      (_) => _refresh(),
    );
  }

  void _refresh() => ref.invalidate(publicTripProvider(widget.publicationId));

  Future<void> _block(PublicTripView trip) async {
    final name = trip.author.displayName;
    final confirmed = await showAppConfirmSheet(
      context,
      icon: Icons.block,
      iconColor: AppColors.danger,
      iconTint: AppColors.danger.withValues(alpha: 0.12),
      title: 'Block $name?',
      body: "You won't see their public trips again.",
      primaryLabel: 'Block',
      primaryColor: AppColors.danger,
    );
    if (!confirmed || !mounted) return;
    try {
      await ref
          .read(publicTripViewerActionsProvider.notifier)
          .setAuthorBlocked(trip.id, trip.author.id, blocked: true);
    } on PublicTripFailure catch (failure) {
      if (!mounted) return;
      showAppToast(
        context,
        variant: AppToastVariant.error,
        title: "Couldn't block $name",
        message: failure.message,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(publicTripProvider(widget.publicationId));
    final trip = async.value;
    if (!async.hasError && trip != null) {
      // The replay carries its own back button, over the map.
      return Scaffold(
        backgroundColor: Colors.white,
        body: PublicTripReplay(
          key: ValueKey(trip.revision),
          trip: trip,
          onOpenDirections: widget.onOpenDirections,
          onReport: () => unawaited(
            showPublicTripReportSheet(context, publicationId: trip.id),
          ),
          onBlock: () => unawaited(_block(trip)),
        ),
      );
    }
    final Widget body;
    if (async.hasError) {
      // Fail closed: if access cannot be confirmed, show nothing of the trip.
      body = PublicTripUnavailable(offline: true, onRetry: _refresh);
    } else if (!async.hasValue) {
      body = const _Skeleton();
    } else {
      body = const PublicTripUnavailable();
    }
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        // Without this the Stack shrinks to the back button and squeezes the
        // page into a 64 px box.
        fit: StackFit.expand,
        children: [
          Positioned.fill(child: body),
          // Positioned, so it keeps its own small size instead of being
          // stretched over the whole screen by the expanding Stack.
          Positioned(
            top: 0,
            left: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 0, 0),
                child: AppBackButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Skeleton extends StatelessWidget {
  const _Skeleton();

  @override
  Widget build(BuildContext context) {
    return const AppShimmer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 42, child: AppSkeleton(radius: 0)),
          Expanded(
            flex: 58,
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppSkeleton(width: 220, height: 24),
                  SizedBox(height: 14),
                  AppSkeleton(width: 160, height: 16),
                  SizedBox(height: 22),
                  AppSkeleton(height: 64, radius: 14),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
