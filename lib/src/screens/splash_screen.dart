import 'dart:async';

import 'package:flutter/material.dart';

import '../design/app_colors.dart';
import '../widgets/app_icon_badge.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({
    super.key,
    required this.onComplete,
    this.preload,
    this.minimumDuration = const Duration(milliseconds: 800),
  });

  final VoidCallback onComplete;
  final Future<void> Function(BuildContext context)? preload;
  final Duration minimumDuration;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Timer? _timer;
  var _minimumDurationComplete = false;
  var _preloadComplete = false;
  var _didComplete = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer(widget.minimumDuration, () {
      _minimumDurationComplete = true;
      _completeIfReady();
    });
    _runPreload();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _runPreload() async {
    final preload = widget.preload;
    if (preload == null) {
      _preloadComplete = true;
      _completeIfReady();
      return;
    }

    try {
      await preload(context);
    } catch (_) {
      // The sign-in screen still has its own placeholder path. Preload is
      // an optimization, so a decode/cache failure should not trap startup.
    }

    if (!mounted) {
      return;
    }

    _preloadComplete = true;
    _completeIfReady();
  }

  void _completeIfReady() {
    if (_didComplete || !_minimumDurationComplete || !_preloadComplete) {
      return;
    }

    _didComplete = true;
    widget.onComplete();
  }

  void _completeAfterTap() {
    _minimumDurationComplete = true;
    _completeIfReady();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.splashBackground,
      body: SafeArea(
        child: InkWell(
          onTap: _completeAfterTap,
          child: const Center(child: AppIconBadge(size: 100)),
        ),
      ),
    );
  }
}
