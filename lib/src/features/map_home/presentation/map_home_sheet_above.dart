import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// Rides just above a [DraggableScrollableSheet]'s top edge while the sheet
/// is collapsed (for example a status pill) and hides once it is dragged
/// open. It follows [controller]'s extent itself, so the sheet needs no
/// extra state for it.
class MapHomeSheetAbove extends StatefulWidget {
  const MapHomeSheetAbove({
    super.key,
    required this.controller,
    required this.height,
    required this.expandedSize,
    required this.collapsedSize,
    required this.startsExpanded,
    required this.child,
  });

  final DraggableScrollableController controller;

  /// The space the sheet's fractions are of.
  final double height;
  final double expandedSize;
  final double collapsedSize;
  final bool startsExpanded;
  final Widget child;

  @override
  State<MapHomeSheetAbove> createState() => _MapHomeSheetAboveState();
}

class _MapHomeSheetAboveState extends State<MapHomeSheetAbove> {
  /// The sheet's extent as a fraction of its space; null until attached.
  double? _extent;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_sync);
  }

  @override
  void didUpdateWidget(MapHomeSheetAbove old) {
    super.didUpdateWidget(old);
    if (old.controller != widget.controller) {
      old.controller.removeListener(_sync);
      widget.controller.addListener(_sync);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_sync);
    super.dispose();
  }

  /// The controller also notifies mid-layout, when listeners must not
  /// rebuild: wait for the frame to finish.
  void _sync() {
    if (!mounted || !widget.controller.isAttached) return;
    if (SchedulerBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      SchedulerBinding.instance.addPostFrameCallback((_) => _sync());
      return;
    }
    final size = widget.controller.size;
    if (size != _extent) setState(() => _extent = size);
  }

  @override
  Widget build(BuildContext context) {
    final size =
        _extent ??
        (widget.startsExpanded ? widget.expandedSize : widget.collapsedSize);
    final open = size > (widget.collapsedSize + widget.expandedSize) / 2;
    return Positioned(
      left: 12,
      bottom: size * widget.height + 10,
      child: open ? const SizedBox.shrink() : widget.child,
    );
  }
}
