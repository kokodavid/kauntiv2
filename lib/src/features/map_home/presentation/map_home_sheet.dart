import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../../../design/app_colors.dart';

class MapHomeSheet extends StatefulWidget {
  const MapHomeSheet({super.key, required this.children});

  final List<Widget> children;

  @override
  State<MapHomeSheet> createState() => _MapHomeSheetState();
}

class _MapHomeSheetState extends State<MapHomeSheet> {
  static const _peekSize = 0.14;
  static const _maxSize = 0.88;
  double? _contentHeight;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const chromeHeight = 10.0 + 4.0 + 14.0 + 110.0;
        var expandedSize = _maxSize;
        if (_contentHeight != null && constraints.maxHeight > 0) {
          expandedSize = ((_contentHeight! + chromeHeight) /
                  constraints.maxHeight)
              .clamp(_peekSize, _maxSize);
        }
        final collapsedSize = math.min(_peekSize, expandedSize);

        return DraggableScrollableSheet(
          initialChildSize: collapsedSize,
          minChildSize: collapsedSize,
          maxChildSize: expandedSize,
          snap: true,
          snapSizes: collapsedSize == expandedSize
              ? null
              : [collapsedSize, expandedSize],
          builder: (context, scrollController) {
            return DecoratedBox(
              decoration: const BoxDecoration(
                color: AppColors.pageBackground,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
                padding: const EdgeInsets.fromLTRB(24, 10, 24, 110),
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
                  _MeasureSize(
                    onChange: (size) {
                      if (!mounted) return;
                      if (_contentHeight == size.height) return;
                      setState(() => _contentHeight = size.height);
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (var i = 0; i < widget.children.length; i++) ...[
                          if (i > 0) const SizedBox(height: 16),
                          widget.children[i],
                        ],
                      ],
                    ),
                  ),
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
