import 'package:flutter/material.dart';

import '../../../design/app_colors.dart';
import '../../../widgets/app_progress_indicator.dart';

/// Loads a detail page's data once and renders loading, error (with retry
/// and back) and data states explicitly.
class DetailAsyncBody<T> extends StatefulWidget {
  const DetailAsyncBody({
    super.key,
    required this.load,
    required this.builder,
    required this.errorMessage,
  });

  final Future<T> Function() load;
  final Widget Function(BuildContext context, T data) builder;
  final String errorMessage;

  @override
  State<DetailAsyncBody<T>> createState() => _DetailAsyncBodyState<T>();
}

class _DetailAsyncBodyState<T> extends State<DetailAsyncBody<T>> {
  late Future<T> _future = widget.load();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<T>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.hasData)
          return widget.builder(context, snapshot.data as T);
        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  widget.errorMessage,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.mutedForeground),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => setState(() => _future = widget.load()),
                  child: const Text('Try again'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  child: const Text('Go back'),
                ),
              ],
            ),
          );
        }
        return const Center(
          child: AppProgressIndicator(color: AppColors.accent, radius: 14),
        );
      },
    );
  }
}
