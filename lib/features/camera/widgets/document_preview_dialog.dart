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
      ..color = Colors.white
      ..strokeWidth = 2.0
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

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

      canvas.save();
      final outerPath = Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
      final dimmedPath = Path.combine(PathOperation.difference, outerPath, path);
      canvas.drawPath(dimmedPath, Paint()..color = Colors.black.withValues(alpha: 0.6));
      canvas.restore();

      canvas.drawPath(path, paint);
    } else {
      const padding = 40.0;
      final rect = Rect.fromLTWH(
        padding,
        padding,
        size.width - (padding * 2),
        size.height - (padding * 2),
      );
      canvas.drawRect(rect, paint);
      
      final cornerPaint = Paint()
        ..color = Colors.white
        ..strokeWidth = 4.0
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;

      const cornerSize = 24.0;
      canvas.drawLine(rect.topLeft, rect.topLeft + const Offset(cornerSize, 0), cornerPaint);
      canvas.drawLine(rect.topLeft, rect.topLeft + const Offset(0, cornerSize), cornerPaint);
      canvas.drawLine(rect.topRight, rect.topRight + const Offset(-cornerSize, 0), cornerPaint);
      canvas.drawLine(rect.topRight, rect.topRight + const Offset(0, cornerSize), cornerPaint);
      canvas.drawLine(rect.bottomLeft, rect.bottomLeft + const Offset(cornerSize, 0), cornerPaint);
      canvas.drawLine(rect.bottomLeft, rect.bottomLeft + const Offset(0, -cornerSize), cornerPaint);
      canvas.drawLine(rect.bottomRight, rect.bottomRight + const Offset(-cornerSize, 0), cornerPaint);
      canvas.drawLine(rect.bottomRight, rect.bottomRight + const Offset(0, -cornerSize), cornerPaint);
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
      backgroundColor: const Color(0xFF121212),
      surfaceTintColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            color: const Color(0xFF1E1E1E),
            width: double.infinity,
            alignment: Alignment.center,
            child: const Text(
              'Adjust Boundaries',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ),
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
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            width: _handleSize,
                            height: _handleSize,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: draggedCornerIndex == i
                                  ? Colors.white
                                  : Colors.white.withValues(alpha: 0.2),
                              border: Border.all(
                                color: Colors.white, 
                                width: draggedCornerIndex == i ? 0 : 2
                              ),
                              boxShadow: [
                                if (draggedCornerIndex == i)
                                  BoxShadow(
                                    color: Colors.white.withValues(alpha: 0.5), 
                                    blurRadius: 10, 
                                    spreadRadius: 2,
                                  )
                              ],
                            ),
                            child: draggedCornerIndex == i
                                ? Center(
                                    child: Container(
                                      width: 8,
                                      height: 8,
                                      decoration: const BoxDecoration(
                                        color: Colors.black,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  )
                                : null,
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
          Container(
            color: const Color(0xFF1E1E1E),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              children: [
                const Text(
                  'Drag the corners to align with the document edges',
                  style: TextStyle(color: Colors.white54, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white70,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        widget.onDiscard();
                      },
                      child: const Text(
                        'DISCARD',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                      ),
                      onPressed: () {
                        widget.onKeep(corners);
                      },
                      child: const Text(
                        'KEEP',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
