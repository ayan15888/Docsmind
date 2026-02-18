import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

/// Custom painter to draw document boundaries with corner indicators.
class DocumentBoundaryPainter extends CustomPainter {
  final bool hasDocument;
  final List<Offset> corners;

  DocumentBoundaryPainter({
    required this.hasDocument,
    this.corners = const [],
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (!hasDocument) return;

    final paint = Paint()
      ..color = Colors.green
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke;

    final cornerPaint = Paint()
      ..color = Colors.green
      ..strokeWidth = 5.0
      ..style = PaintingStyle.stroke;

    final cornerFillPaint = Paint()
      ..color = Colors.green
      ..style = PaintingStyle.fill;

    if (corners.isNotEmpty && corners.length >= 4) {
      final scaledCorners = <Offset>[];
      for (final corner in corners) {
        final scaledX = corner.dx <= 1.0 ? corner.dx * size.width : corner.dx;
        final scaledY = corner.dy <= 1.0 ? corner.dy * size.height : corner.dy;
        scaledCorners.add(Offset(scaledX, scaledY));
      }
      final path = Path();
      path.moveTo(scaledCorners[0].dx, scaledCorners[0].dy);
      for (int i = 1; i < scaledCorners.length; i++) {
        path.lineTo(scaledCorners[i].dx, scaledCorners[i].dy);
      }
      path.close();
      canvas.drawPath(path, paint);
      for (final corner in scaledCorners) {
        canvas.drawCircle(corner, 8, cornerFillPaint);
        canvas.drawCircle(corner, 8, cornerPaint);
      }
    } else {
      const padding = 40.0;
      final rect = Rect.fromLTWH(
        padding,
        padding,
        size.width - (padding * 2),
        size.height - (padding * 2),
      );
      canvas.drawRect(rect, paint);
      const cornerSize = 30.0;
      canvas.drawLine(Offset(rect.left, rect.top), Offset(rect.left + cornerSize, rect.top), cornerPaint);
      canvas.drawLine(Offset(rect.left, rect.top), Offset(rect.left, rect.top + cornerSize), cornerPaint);
      canvas.drawLine(Offset(rect.right, rect.top), Offset(rect.right - cornerSize, rect.top), cornerPaint);
      canvas.drawLine(Offset(rect.right, rect.top), Offset(rect.right, rect.top + cornerSize), cornerPaint);
      canvas.drawLine(Offset(rect.left, rect.bottom), Offset(rect.left + cornerSize, rect.bottom), cornerPaint);
      canvas.drawLine(Offset(rect.left, rect.bottom), Offset(rect.left, rect.bottom - cornerSize), cornerPaint);
      canvas.drawLine(Offset(rect.right, rect.bottom), Offset(rect.right - cornerSize, rect.bottom), cornerPaint);
      canvas.drawLine(Offset(rect.right, rect.bottom), Offset(rect.right, rect.bottom - cornerSize), cornerPaint);
    }
  }

  @override
  bool shouldRepaint(DocumentBoundaryPainter oldDelegate) {
    if (oldDelegate.hasDocument != hasDocument) return true;
    if (oldDelegate.corners.length != corners.length) return true;
    for (int i = 0; i < corners.length; i++) {
      if (oldDelegate.corners[i].dx != corners[i].dx || oldDelegate.corners[i].dy != corners[i].dy) return true;
    }
    return false;
  }
}

List<Offset> defaultDocumentCorners() {
  return const [
    Offset(0.1, 0.12),
    Offset(0.9, 0.08),
    Offset(0.92, 0.9),
    Offset(0.08, 0.92),
  ];
}

/// Interactive preview dialog that allows adjusting document corners.
class InteractivePreviewDialog extends StatefulWidget {
  final XFile image;
  final dynamic detectedDoc;
  final void Function(List<Offset>) onKeep;
  final VoidCallback onDiscard;

  const InteractivePreviewDialog({
    super.key,
    required this.image,
    required this.detectedDoc,
    required this.onKeep,
    required this.onDiscard,
  });

  @override
  State<InteractivePreviewDialog> createState() => _InteractivePreviewDialogState();
}

class _InteractivePreviewDialogState extends State<InteractivePreviewDialog> {
  late List<Offset> corners;
  int? draggedCornerIndex;
  late GlobalKey imageKey;
  static const double _handleSize = 40.0;
  static const double _cornerTapRadius = 36.0;

  @override
  void initState() {
    super.initState();
    imageKey = GlobalKey();
    final fromDetection = widget.detectedDoc?.corners;
    corners = (fromDetection != null && fromDetection.length >= 4)
        ? List<Offset>.from(fromDetection)
        : defaultDocumentCorners();
  }

  void _onPointerDown(PointerDownEvent event) {
    final ctx = imageKey.currentContext;
    if (ctx == null) return;
    final RenderBox? renderBox = ctx.findRenderObject() as RenderBox?;
    if (renderBox == null || !renderBox.hasSize) return;
    final localPosition = renderBox.globalToLocal(event.position);
    final w = renderBox.size.width;
    final h = renderBox.size.height;
    for (int i = 0; i < corners.length; i++) {
      final c = corners[i];
      final sx = c.dx <= 1.0 ? c.dx * w : c.dx;
      final sy = c.dy <= 1.0 ? c.dy * h : c.dy;
      if ((Offset(sx, sy) - localPosition).distance < _cornerTapRadius) {
        setState(() => draggedCornerIndex = i);
        return;
      }
    }
  }

  void _onPointerMove(PointerMoveEvent event) {
    if (draggedCornerIndex == null) return;
    final ctx = imageKey.currentContext;
    if (ctx == null) return;
    final RenderBox? renderBox = ctx.findRenderObject() as RenderBox?;
    if (renderBox == null || !renderBox.hasSize) return;
    final localPosition = renderBox.globalToLocal(event.position);
    final w = renderBox.size.width;
    final h = renderBox.size.height;
    setState(() {
      corners[draggedCornerIndex!] = Offset(
        (localPosition.dx / w).clamp(0.0, 1.0),
        (localPosition.dy / h).clamp(0.0, 1.0),
      );
    });
  }

  void _onPointerUp(PointerUpEvent event) {
    setState(() => draggedCornerIndex = null);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final w = constraints.maxWidth;
                final h = constraints.maxHeight;
                if (w <= 0 || h <= 0) return const SizedBox.shrink();
                return Listener(
                  onPointerDown: _onPointerDown,
                  onPointerMove: _onPointerMove,
                  onPointerUp: _onPointerUp,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Image.file(
                        File(widget.image.path),
                        fit: BoxFit.cover,
                        width: w,
                        height: h,
                        key: imageKey,
                      ),
                      CustomPaint(
                        painter: DocumentBoundaryPainter(
                          hasDocument: true,
                          corners: corners,
                        ),
                        size: Size(w, h),
                      ),
                      for (int i = 0; i < corners.length; i++)
                        Positioned(
                          left: (corners[i].dx <= 1.0 ? corners[i].dx * w : corners[i].dx) - _handleSize / 2,
                          top: (corners[i].dy <= 1.0 ? corners[i].dy * h : corners[i].dy) - _handleSize / 2,
                          child: Container(
                            width: _handleSize,
                            height: _handleSize,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: draggedCornerIndex == i
                                  ? Colors.blue.withValues(alpha: 0.9)
                                  : Colors.green.withValues(alpha: 0.8),
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: const Icon(Icons.edit, color: Colors.white, size: 20),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Container(
              color: Colors.green.withValues(alpha: 0.2),
              padding: const EdgeInsets.all(8.0),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check, color: Colors.green),
                  SizedBox(width: 8),
                  Text(
                    'Drag corners to adjust, then tap Keep',
                    style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  widget.onDiscard();
                },
                icon: const Icon(Icons.close),
                label: const Text('Discard'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  widget.onKeep(corners);
                },
                icon: const Icon(Icons.check),
                label: const Text('Keep'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
