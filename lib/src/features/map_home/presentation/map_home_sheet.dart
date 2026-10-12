import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';

import '../../../core/widgets/app_bottom_nav.dart';
import '../../../design/app_colors.dart';

/// Home's draggable bottom sheet.
///
/// With [collapsed] the sheet shows that one card while it is collapsed and
/// [children] once it is dragged open; without it, [children] show in both
/// states and the collapsed sheet is a peek. [startsExpanded] opens it
/// expanded (the win layouts). A sheet the user has opened is never
/// collapsed for them: the content swaps in place when the layout changes.
class MapHomeSheet extends StatefulWidget {
  const MapHomeSheet({
    super.key,
    required this.children,
    this.collapsed,
    this.collapsedHeight = 0,
    this.collapsedUnderNav = false,
    this.startsExpanded = false,
  });

  final List<Widget> children;

  /// The one-card collapsed content, [collapsedHeight] tall.
  final Widget? collapsed;
  final double collapsedHeight;

  /// The collapsed content runs on beneath the floating tab bar (so the
  /// bar floats over it) instead of stopping above it; [collapsedHeight]
  /// then already includes the bar's room.
  final bool collapsedUnderNav;
  final bool startsExpanded;

  @override
  State<MapHomeSheet> createState() => _MapHomeSheetState();
}

class _MapHomeSheetState extends State<MapHomeSheet> {
  static const _peekSize = 0.14;
  static const _maxSize = 0.88;

  /// The one space between sheet sections.
  static const _sectionGap = 28.0;

  /// Handle row, top padding and the room kept for the tab bar, which
  /// follows the bar's own height and the phone's system navigation inset.
  static double _chrome(BuildContext context) =>
      10.0 + 4.0 + 14.0 + AppBottomNav.clearance(context);

  final _controller = DraggableScrollableController();
  double? _contentHeight;
  bool _showCollapsed = true;

  @override
  void initState() {
    super.initState();
    _showCollapsed = widget.collapsed != null && !widget.startsExpanded;
    _controller.addListener(_onExtentChanged);
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_onExtentChanged)
      ..dispose();
    super.dispose();
  }

  double _expandedSize = _maxSize;
  double _collapsedSize = _peekSize;

  void _onExtentChanged() {
    if (widget.collapsed == null || !_controller.isAttached) return;
    final midpoint = (_collapsedSize + _expandedSize) / 2;
    final showCollapsed = _controller.size < midpoint;
    if (showCollapsed == _showCollapsed || !mounted) return;
    // The controller also notifies while the sheet is being laid out (its
    // extent is replaced when the sheet's sizes change), when setState is
    // not allowed: wait for the frame to finish.
    if (SchedulerBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      SchedulerBinding.instance.addPostFrameCallback((_) => _onExtentChanged());
      return;
    }
    setState(() => _showCollapsed = showCollapsed);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final hasCollapsed = widget.collapsed != null;
        var expandedSize = _maxSize;
        if (_contentHeight != null && constraints.maxHeight > 0) {
          expandedSize =
              ((_contentHeight! + _chrome(context)) / constraints.maxHeight)
                  .clamp(_peekSize, _maxSize);
        }
        final peek = hasCollapsed && constraints.maxHeight > 0
            ? (widget.collapsedHeight +
                      (widget.collapsedUnderNav
                          ? 10.0 + 4.0 + 14.0
                          : _chrome(context))) /
                  constraints.maxHeight
            : _peekSize;
        final collapsedSize = math.min(peek, expandedSize);
        _expandedSize = expandedSize;
        _collapsedSize = collapsedSize;

        return DraggableScrollableSheet(
          controller: _controller,
          initialChildSize: widget.startsExpanded
              ? expandedSize
              : collapsedSize,
          minChildSize: collapsedSize,
          maxChildSize: expandedSize,
          snap: true,
          snapSizes: collapsedSize == expandedSize
              ? null
              : [collapsedSize, expandedSize],
          builder: (context, scrollController) {
            final showCollapsed = hasCollapsed && _showCollapsed;
            final expanded = _MeasureSize(
              onChange: (size) {
                if (!mounted) return;
                if (_contentHeight == size.height) return;
                setState(() => _contentHeight = size.height);
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Each section brings its own gap, and only when it shows
                  // something, so a section that hides itself (saved plans,
                  // an empty row) can't leave a double gap behind.
                  for (var i = 0; i < widget.children.length; i++)
                    _SectionSlot(
                      gap: i == 0 ? 0 : _sectionGap,
                      child: widget.children[i],
                    ),
                ],
              ),
            );
            return DecoratedBox(
              decoration: const BoxDecoration(
                color: AppColors.pageBackground,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                boxShadow: [
                  BoxShadow(
                    color: Color(0x14000000),
                    offset: Offset(0, -4),
                    blurRadius: 16,
                  ),
                ],
              ),
              child: ListView(
                controller: scrollController,
                padding: EdgeInsets.fromLTRB(
                  20,
                  10,
                  20,
                  AppBottomNav.clearance(context),
                ),
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 14),
                      decoration: BoxDecoration(
                        color: AppColors.trackInactive,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  // Kept mounted (and its tickers off) while expanded, so a
                  // carousel in it keeps its places instead of reloading.
                  if (hasCollapsed)
                    Offstage(
                      offstage: !showCollapsed,
                      child: TickerMode(
                        enabled: showCollapsed,
                        child: widget.collapsed!,
                      ),
                    ),
                  // Kept laid out while collapsed so the expanded height is
                  // known before the user drags.
                  Offstage(offstage: showCollapsed, child: expanded),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _MeasureSize extends SingleChildRenderObjectWidget {
  const _MeasureSize({required this.onChange, required Widget child})
    : super(child: child);

  final ValueChanged<Size> onChange;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _MeasureSizeRenderObject(onChange);
  }

  @override
  void updateRenderObject(BuildContext context, RenderObject renderObject) {
    (renderObject as _MeasureSizeRenderObject).onChange = onChange;
  }
}

class _MeasureSizeRenderObject extends RenderProxyBox {
  _MeasureSizeRenderObject(this.onChange);

  ValueChanged<Size> onChange;
  Size? _oldSize;

  @override
  void performLayout() {
    super.performLayout();
    final newSize = child?.size;
    if (newSize != null && newSize != _oldSize) {
      _oldSize = newSize;
      WidgetsBinding.instance.addPostFrameCallback((_) => onChange(newSize));
    }
  }
}

/// A section plus the gap above it, collapsing to nothing when the section
/// itself has no height. Keeps the space between visible sections exactly
/// one gap however many sections hide.
class _SectionSlot extends SingleChildRenderObjectWidget {
  const _SectionSlot({required this.gap, required Widget child})
    : super(child: child);

  final double gap;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderSectionSlot(gap);

  @override
  void updateRenderObject(
    BuildContext context,
    covariant _RenderSectionSlot renderObject,
  ) => renderObject.gap = gap;
}

class _RenderSectionSlot extends RenderShiftedBox {
  _RenderSectionSlot(this._gap) : super(null);

  double _gap;

  set gap(double value) {
    if (_gap == value) return;
    _gap = value;
    markNeedsLayout();
  }

  Size _sized(Size child) => child.height == 0
      ? Size(child.width, 0)
      : Size(child.width, child.height + _gap);

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    final c = child;
    if (c == null) return constraints.smallest;
    return constraints.constrain(_sized(c.getDryLayout(constraints)));
  }

  @override
  void performLayout() {
    final c = child;
    if (c == null) {
      size = constraints.smallest;
      return;
    }
    c.layout(constraints, parentUsesSize: true);
    final empty = c.size.height == 0;
    (c.parentData! as BoxParentData).offset = Offset(0, empty ? 0 : _gap);
    size = constraints.constrain(_sized(c.size));
  }
}
