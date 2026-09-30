import 'dart:async';

import 'package:flutter/material.dart';

import '../../design/app_colors.dart';

/// A loading shimmer: one light band sweeping across every [AppSkeleton]
/// below it, in step, as if over one surface. Wrap a whole loading layout
/// in it. With reduced motion the placeholders stay still.
class AppShimmer extends StatefulWidget {
  const AppShimmer({super.key, required this.child});

  final Widget child;

  static AppShimmerState? of(BuildContext context) =>
      context.findAncestorStateOfType<AppShimmerState>();

  @override
  State<AppShimmer> createState() => AppShimmerState();
}

class AppShimmerState extends State<AppShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  static const _base = AppColors.trackInactive;
  static const _highlight = Color(0xFFF4F7FB);

  Listenable get changes => _controller;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      unawaited(_controller.repeat());
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// The band's gradient at this moment, across the shimmer's own box.
  LinearGradient get gradient => LinearGradient(
    begin: const Alignment(-1, -0.3),
    end: const Alignment(1, 0.3),
    colors: const [_base, _highlight, _base],
    stops: const [0.35, 0.5, 0.65],
    transform: _Slide(_controller.value),
  );

  Size get size => (context.findRenderObject()! as RenderBox).size;

  Offset offsetOf(RenderBox descendant) => descendant.localToGlobal(
    Offset.zero,
    ancestor: context.findRenderObject(),
  );

  @override
  Widget build(BuildContext context) => widget.child;
}

class _Slide extends GradientTransform {
  const _Slide(this.t);

  final double t;

  @override
  Matrix4 transform(Rect bounds, {TextDirection? textDirection}) =>
      Matrix4.translationValues(bounds.width * (t * 2 - 1), 0, 0);
}

/// A placeholder block (or circle) that picks up [AppShimmer]'s band.
class AppSkeleton extends StatefulWidget {
  const AppSkeleton({
    super.key,
    this.width = double.infinity,
    this.height,
    this.radius = 6,
    this.circle = false,
  });

  final double width;
  final double? height;
  final double radius;
  final bool circle;

  @override
  State<AppSkeleton> createState() => _AppSkeletonState();
}

class _AppSkeletonState extends State<AppSkeleton> {
  Listenable? _changes;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _changes?.removeListener(_repaint);
    _changes = AppShimmer.of(context)?.changes;
    _changes?.addListener(_repaint);
  }

  @override
  void dispose() {
    _changes?.removeListener(_repaint);
    super.dispose();
  }

  void _repaint() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final box = Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: AppShimmerState._base,
        shape: widget.circle ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: widget.circle
            ? null
            : BorderRadius.circular(widget.radius),
      ),
    );
    final shimmer = AppShimmer.of(context);
    final self = context.findRenderObject() as RenderBox?;
    if (shimmer == null || self == null || !self.hasSize) return box;
    final area = shimmer.size;
    final offset = shimmer.offsetOf(self);
    return ShaderMask(
      blendMode: BlendMode.srcATop,
      shaderCallback: (bounds) => shimmer.gradient.createShader(
        Rect.fromLTWH(-offset.dx, -offset.dy, area.width, area.height),
      ),
      child: box,
    );
  }
}
