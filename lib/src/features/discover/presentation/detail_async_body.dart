import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/fail_fast.dart';
import '../../../core/widgets/app_back_button.dart';
import '../../../core/widgets/offline_screen.dart';
import '../../../design/app_colors.dart';
import '../../../widgets/app_progress_indicator.dart';

/// Loads a detail page's data once and renders loading, error and data
/// states explicitly. A page that can't load shows the shared "You're
/// offline" screen (or "Couldn't load this page" when the phone is online)
/// under a Back button, and loads by itself when the connection returns.
class DetailAsyncBody<T> extends ConsumerStatefulWidget {
  const DetailAsyncBody({
    super.key,
    required this.load,
    required this.builder,
  });

  final Future<T> Function() load;
  final Widget Function(BuildContext context, T data) builder;

  @override
  ConsumerState<DetailAsyncBody<T>> createState() =>
      _DetailAsyncBodyState<T>();
}

class _DetailAsyncBodyState<T> extends ConsumerState<DetailAsyncBody<T>> {
  // Fails at once offline instead of waiting out the network's timeout.
  late Future<T> _future = failFastWidget(ref, widget.load);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<T>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return widget.builder(context, snapshot.data as T);
        }
        if (snapshot.hasError) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                child: AppBackButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
              ),
              Expanded(
                child: OfflineScreen(
                  onRetry: () => setState(
                    () => _future = failFastWidget(ref, widget.load),
                  ),
                ),
              ),
            ],
          );
        }
        return const Center(
          child: AppProgressIndicator(color: AppColors.accent, radius: 14),
        );
      },
    );
  }
}
