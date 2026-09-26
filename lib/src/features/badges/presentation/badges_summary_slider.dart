import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../../../design/app_colors.dart';

/// The cards at the top of the Badges tab (counties claimed, tiers) as a
/// horizontal slider with dots below. The slider takes the height of the
/// page in view, easing between pages while swiping and following a page
/// that grows (the tiers card expanding).
class BadgesSummarySlider extends StatefulWidget {
  const BadgesSummarySlider({super.key, required this.pages});

  final List<Widget> pages;

  @override
  State<BadgesSummarySlider> createState() => _BadgesSummarySliderState();
}

class _BadgesSummarySliderState extends State<BadgesSummarySlider> {
  final _controller = PageController();
  late List<double> _heights = List.filled(widget.pages.length, 0);
  double _page = 0;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      final page = _controller.page;
      if (page != null && page != _page) setState(() => _page = page);
    });
  }

  @override
  void didUpdateWidget(BadgesSummarySlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pages.length != widget.pages.length) {
      _heights = List.filled(widget.pages.length, 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onHeight(int index, double height) {
    if (!mounted || _heights[index] == height) return;
    setState(() => _heights[index] = height);
  }

  /// The height between the two pages either side of the scroll position.
  /// A page not measured yet borrows its neighbour's height.
  double get _height {
    final lower = _page.floor().clamp(0, _heights.length - 1);
    final upper = _page.ceil().clamp(0, _heights.length - 1);
    final a = _heights[lower] > 0 ? _heights[lower] : _heights[upper];
    final b = _heights[upper] > 0 ? _heights[upper] : a;
    return a + (b - a) * (_page - lower);
  }

  @override
  Widget build(BuildContext context) {
    final height = _height;
    final pager = PageView.builder(
      controller: _controller,
      itemCount: widget.pages.length,
      itemBuilder: (context, i) => OverflowBox(
        alignment: Alignment.topCenter,
        minHeight: 0,
        maxHeight: double.infinity,
        child: _SizeReporter(
          onHeight: (h) => _onHeight(i, h),
          child: widget.pages[i],
        ),
      ),
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Before the first measurement, lay the first page out plainly so
        // there's no empty frame.
        if (height == 0)
          _SizeReporter(
            onHeight: (h) => _onHeight(0, h),
            child: widget.pages.first,
          )
        else
          SizedBox(height: height, child: pager),
        const SizedBox(height: 10),
        _Dots(
          count: widget.pages.length,
          page: _page,
          onTap: (i) => _controller.animateToPage(
            i,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
          ),
        ),
      ],
    );
  }
}

class _Dots extends StatelessWidget {
  const _Dots({required this.count, required this.page, required this.onTap});

  final int count;
  final double page;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < count; i++)
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => onTap(i),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 4),
              child: _Dot(active: (1 - (page - i).abs()).clamp(0, 1)),
            ),
          ),
      ],
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.active});

  /// 1 on its page, 0 away from it.
  final double active;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 6 + 12 * active,
      height: 6,
      decoration: BoxDecoration(
        color: Color.lerp(AppColors.lockedStroke, AppColors.accent, active),
        borderRadius: BorderRadius.circular(3),
      ),
    );
  }
}

/// Reports its child's laid-out height after each layout that changes it.
class _SizeReporter extends SingleChildRenderObjectWidget {
  const _SizeReporter({required this.onHeight, required super.child});

  final ValueChanged<double> onHeight;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderSizeReporter(onHeight);

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderSizeReporter renderObject,
  ) {
    renderObject.onHeight = onHeight;
  }
}

class _RenderSizeReporter extends RenderProxyBox {
  _RenderSizeReporter(this.onHeight);

  ValueChanged<double> onHeight;
  double? _last;

  @override
  void performLayout() {
    super.performLayout();
    final height = size.height;
    if (height == _last) return;
    _last = height;
    WidgetsBinding.instance.addPostFrameCallback((_) => onHeight(height));
  }
}
