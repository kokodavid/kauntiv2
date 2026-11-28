import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// Layout helpers for [MapHomeSheet]'s content.
class MapHomeMeasureSize extends SingleChildRenderObjectWidget {
  const MapHomeMeasureSize({
    super.key,
    required this.onChange,
    required Widget child,
  }) : super(child: child);

  final ValueChanged<Size> onChange;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return RenderMeasureSize(onChange);
  }

  @override
  void updateRenderObject(BuildContext context, RenderObject renderObject) {
    (renderObject as RenderMeasureSize).onChange = onChange;
  }
}

class RenderMeasureSize extends RenderProxyBox {
  RenderMeasureSize(this.onChange);

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
class MapHomeSectionSlot extends SingleChildRenderObjectWidget {
  const MapHomeSectionSlot({
    super.key,
    required this.gap,
    required Widget child,
  }) : super(child: child);

  final double gap;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      RenderMapHomeSectionSlot(gap);

  @override
  void updateRenderObject(
    BuildContext context,
    covariant RenderMapHomeSectionSlot renderObject,
  ) => renderObject.gap = gap;
}

class RenderMapHomeSectionSlot extends RenderShiftedBox {
  RenderMapHomeSectionSlot(this._gap) : super(null);

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
