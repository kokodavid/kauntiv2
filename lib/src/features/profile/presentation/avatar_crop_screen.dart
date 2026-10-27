import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../../../design/app_colors.dart';

/// Frames a picked photo before it becomes the profile picture: drag and
/// pinch to position it under the round mask (which is how it will appear),
/// then "Use photo" returns the framed square as PNG bytes, or null when
/// cancelled.
class AvatarCropScreen extends StatefulWidget {
  const AvatarCropScreen({super.key, required this.bytes});

  final Uint8List bytes;

  static Future<Uint8List?> open(BuildContext context, Uint8List bytes) {
    return Navigator.of(context, rootNavigator: true).push<Uint8List>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => AvatarCropScreen(bytes: bytes),
      ),
    );
  }

  @override
  State<AvatarCropScreen> createState() => _AvatarCropScreenState();
}

class _AvatarCropScreenState extends State<AvatarCropScreen> {
  static const _outputSize = 512.0;
  final _frame = GlobalKey();
  bool _busy = false;

  Future<void> _confirm() async {
    final boundary =
        _frame.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null || _busy) return;
    setState(() => _busy = true);
    try {
      final image = await boundary.toImage(
        pixelRatio: _outputSize / boundary.size.width,
      );
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      if (!mounted) return;
      Navigator.of(context).pop(data?.buffer.asUint8List());
    } on Object {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 20, 20, 4),
              child: Text(
                'Adjust your photo',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const Text(
              'Drag and pinch to frame it',
              style: TextStyle(color: Colors.white60, fontSize: 13),
            ),
            Expanded(
              child: Center(
                child: LayoutBuilder(
                  builder: (context, box) {
                    final side = (box.maxWidth - 32).clamp(200.0, 380.0);
                    return SizedBox(
                      width: side,
                      height: side,
                      child: Stack(
                        children: [
                          RepaintBoundary(
                            key: _frame,
                            child: InteractiveViewer(
                              minScale: 1,
                              maxScale: 6,
                              child: Image.memory(
                                widget.bytes,
                                width: side,
                                height: side,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          const Positioned.fill(
                            child: IgnorePointer(
                              child: CustomPaint(painter: _CircleMask()),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _busy
                          ? null
                          : () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white38),
                        minimumSize: const Size.fromHeight(48),
                        shape: const StadiumBorder(),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: _busy ? null : _confirm,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        minimumSize: const Size.fromHeight(48),
                        shape: const StadiumBorder(),
                      ),
                      child: _busy
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Use photo'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Dims everything outside the circle the profile picture will show.
class _CircleMask extends CustomPainter {
  const _CircleMask();

  @override
  void paint(Canvas canvas, Size size) {
    final circle = Rect.fromLTWH(0, 0, size.width, size.height);
    final outside = Path.combine(
      PathOperation.difference,
      Path()..addRect(circle),
      Path()..addOval(circle),
    );
    canvas.drawPath(
      outside,
      Paint()..color = Colors.black.withValues(alpha: 0.62),
    );
    canvas.drawOval(
      circle.deflate(1),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = Colors.white,
    );
  }

  @override
  bool shouldRepaint(_CircleMask oldDelegate) => false;
}
