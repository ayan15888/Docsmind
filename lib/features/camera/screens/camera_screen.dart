import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:camera/camera.dart';
import 'package:docsmind/features/document_scanner/services/document_scanner_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:docsmind/core/providers.dart';
import 'package:docsmind/features/camera/providers/camera_providers.dart';
import 'package:docsmind/features/camera/widgets/camera_control_bar.dart';
import 'package:docsmind/features/camera/widgets/camera_preview_layer.dart';
import 'package:docsmind/features/camera/widgets/camera_mode_slider.dart';
import 'package:docsmind/features/camera/widgets/camera_action_buttons.dart';
import 'package:docsmind/features/camera/widgets/document_preview_dialog.dart';
import 'package:docsmind/features/camera/widgets/scanned_documents_stack.dart';

class CameraScreen extends ConsumerStatefulWidget {
  const CameraScreen({super.key});

  @override
  ConsumerState<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends ConsumerState<CameraScreen> {
  int _consecutiveDetections = 0;
  int _frameCount = 0;
  bool _isStreamActive = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _applyCameraSettings(ref);
      _maybeStartAutoCaptureStream(ref);
    });
  }

  @override
  void dispose() {
    _stopStream();
    super.dispose();
  }

  Future<void> _applyCameraSettings(WidgetRef ref) async {
    final controller = await ref.read(cameraControllerProvider.future);
    if (controller == null || !mounted) return;
    _applyFlash(ref.read(cameraFlashModeProvider));
    _applyFocus(ref.read(cameraFocusModeProvider));
    await _initZoomRange(controller);
    _applyZoom(ref.read(cameraZoomLevelProvider));
  }

  void _applyFlash(FlashMode mode) {
    final f =
        ref.read(cameraControllerProvider).valueOrNull?.setFlashMode(mode);
    if (f != null) unawaited(f);
  }

  void _applyFocus(FocusMode mode) {
    final f =
        ref.read(cameraControllerProvider).valueOrNull?.setFocusMode(mode);
    if (f != null) unawaited(f);
  }

  Future<void> _initZoomRange(CameraController controller) async {
    try {
      final min = await controller.getMinZoomLevel();
      final max = await controller.getMaxZoomLevel();
      ref.read(cameraMinZoomProvider.notifier).state = min;
      ref.read(cameraMaxZoomProvider.notifier).state = max;
      final current = ref.read(cameraZoomLevelProvider);
      ref.read(cameraZoomLevelProvider.notifier).state =
          current.clamp(min, max);
    } catch (_) {
      // Keep defaults if unsupported.
    }
  }

  void _applyZoom(double zoom) {
    final controller = ref.read(cameraControllerProvider).valueOrNull;
    if (controller == null) return;
    final min = ref.read(cameraMinZoomProvider);
    final max = ref.read(cameraMaxZoomProvider);
    final clamped = zoom.clamp(min, max);
    ref.read(cameraZoomLevelProvider.notifier).state = clamped;
    unawaited(controller.setZoomLevel(clamped));
  }

  Future<void> _stopStream() async {
    if (!_isStreamActive) return;
    final controller = ref.read(cameraControllerProvider).valueOrNull;
    if (controller != null) {
      try {
        await controller.stopImageStream();
      } catch (_) {}
    }
    if (mounted) {
      setState(() {
        _isStreamActive = false;
        _consecutiveDetections = 0;
        _frameCount = 0;
      });
    }
  }

  Future<void> _maybeStartAutoCaptureStream(WidgetRef ref) async {
    if (!ref.read(cameraAutoCaptureProvider)) return;
    final controller = await ref.read(cameraControllerProvider.future);
    if (controller == null || !mounted || _isStreamActive) return;
    if (!controller.value.isStreamingImages) {
      try {
        await controller.startImageStream(_onCameraImage);
        if (mounted) setState(() => _isStreamActive = true);
      } catch (e) {
        debugPrint('Auto-capture stream error: $e');
        if (mounted) ref.read(cameraAutoCaptureProvider.notifier).state = false;
      }
    }
  }

  void _onCameraImage(CameraImage image) {
    if (!mounted) return;
    _frameCount++;
    if (_frameCount % 3 != 0) return;
    final scanner = ref.read(documentScannerProvider);
    final live = scanner.detectDocumentInCameraImageLive(image);
    final detected = live?.isDetected ?? false;

    // Update live overlay providers.
    ref.read(liveDocumentDetectedProvider.notifier).state = detected;
    if (detected && live != null && live.corners.isNotEmpty) {
      ref.read(liveDocumentCornersProvider.notifier).state = live.corners;
    } else {
      ref.read(liveDocumentCornersProvider.notifier).state = const [];
    }
    if (!mounted) return;
    setState(() {
      if (detected) {
        _consecutiveDetections++;
      } else {
        _consecutiveDetections = 0;
      }
    });
    if (_consecutiveDetections >= 2) {
      _consecutiveDetections = 0;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await _stopStream();
        if (mounted) await _captureAndShowPreview();
        if (mounted && ref.read(cameraAutoCaptureProvider)) {
          await _maybeStartAutoCaptureStream(ref);
        }
      });
    }
  }

  Future<void> _captureAndShowPreview() async {
    try {
      ref.read(isCapturingProvider.notifier).state = true;
      ref.read(errorMessageProvider.notifier).state = null;

      final controller = ref.read(cameraControllerProvider).valueOrNull;
      if (controller == null || !mounted) {
        ref.read(isCapturingProvider.notifier).state = false;
        return;
      }

      final image = await controller.takePicture();

      ref.read(capturedImageProvider.notifier).state = image;
      ref.read(cameraPathProvider.notifier).state = image.path;

      final scannerService = ref.read(documentScannerProvider);
      // Try native OpenCV detection first
      DetectedDocument? scanResult;
      try {
        scanResult = await scannerService.detectDocumentEdgesNative(image.path);
        debugPrint(
            '[DocsMind] Native OpenCV result: detected=${scanResult?.isDetected}, corners=${scanResult?.corners.length}');
      } catch (e) {
        debugPrint('Native OpenCV detection failed: $e');
      }

      // Fallback to Dart if native fails or returned no detection
      if (scanResult == null || !scanResult.isDetected) {
        debugPrint('[DocsMind] Falling back to Dart edge detection...');
        scanResult = await scannerService.detectDocumentEdges(image.path);
        debugPrint(
            '[DocsMind] Dart result: detected=${scanResult?.isDetected}, corners=${scanResult?.corners.length}');
      }

      if (mounted) {
        ref.read(lastScanResultProvider.notifier).state = scanResult;
        ref.read(isCapturingProvider.notifier).state = false;

        // Automatically open the interactive preview with detected contour points
        await _showPreview(image, scanResult);
      }
    } catch (e) {
      ref.read(errorMessageProvider.notifier).state =
          'Error taking picture: $e';
      debugPrint('Error taking picture: $e');
      ref.read(isCapturingProvider.notifier).state = false;
    }
  }

  Future<void> _takePicture() async {
    if (ref.read(cameraAutoCaptureProvider)) {
      await _stopStream();
    }
    await _captureAndShowPreview();
    if (mounted && ref.read(cameraAutoCaptureProvider)) {
      await _maybeStartAutoCaptureStream(ref);
    }
  }

  Future<void> _showPreview(XFile image, dynamic detectedDoc) async {
    await showDialog(
      context: context,
      builder: (context) => InteractivePreviewDialog(
        image: image,
        detectedDoc: detectedDoc,
        onKeep: (corners) async {
          final scanner = ref.read(documentScannerProvider);
          final mode = ref.read(cameraDocumentModeProvider).name;
          
          // Use native OpenCV for perspective transform + aspect ratio enforcement
          final processedPath = await scanner.processDocumentNative(
            image.path,
            corners,
            filter: 'whiteboard',
            documentMode: mode,
          );
          final pathToSave = processedPath;

          // Update last path + documents and kept lists with the final cropped image.
          ref.read(cameraPathProvider.notifier).state = pathToSave;
          final docs = ref.read(documentsProvider);
          ref.read(documentsProvider.notifier).state = [...docs, pathToSave];

          ref.read(capturedImageProvider.notifier).state = null;
          ref.read(errorMessageProvider.notifier).state = null;
          final kept = ref.read(keptScannedDocumentsProvider);
          ref.read(keptScannedDocumentsProvider.notifier).state = [
            ...kept,
            pathToSave
          ];
          Navigator.pop(context); // Only pop the dialog, stay on camera screen
        },
        onDiscard: () {
          Navigator.pop(context);
          ref.read(capturedImageProvider.notifier).state = null;
          ref.read(errorMessageProvider.notifier).state = null;
        },
      ),
    );
    if (mounted && ref.read(cameraAutoCaptureProvider)) {
      await _maybeStartAutoCaptureStream(ref);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<FlashMode>(
        cameraFlashModeProvider, (_, next) => _applyFlash(next));
    ref.listen<FocusMode>(
        cameraFocusModeProvider, (_, next) => _applyFocus(next));
    ref.listen<double>(cameraZoomLevelProvider, (_, next) => _applyZoom(next));
    ref.listen<bool>(cameraAutoCaptureProvider, (prev, next) {
      if (next) {
        _maybeStartAutoCaptureStream(ref);
      } else {
        _stopStream();
      }
    });

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Camera preview
          const CameraPreviewLayer(),

          // B&W film corners overlay
          Positioned.fill(child: _BWFrameOverlay()),

          // Top control bar
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: CameraControlBar(),
          ),

          // Captured preview bar
          Positioned(
            left: 24,
            right: 24,
            bottom: 160,
            child: Consumer(
              builder: (context, ref, _) {
                final image = ref.watch(capturedImageProvider);
                return AnimatedSwitcher(
                  duration: const Duration(milliseconds: 400),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  transitionBuilder: (child, animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 0.3),
                          end: Offset.zero,
                        ).animate(animation),
                        child: child,
                      ),
                    );
                  },
                  child: image == null
                      ? const SizedBox.shrink(key: ValueKey('empty'))
                      : SizedBox(
                          key: ValueKey(image.path),
                          child: _BWCapturedPreviewBar(
                            image: image,
                            onEdit: () async {
                              final captured = ref.read(capturedImageProvider);
                              if (captured == null) return;
                              final scan = ref.read(lastScanResultProvider);
                              await _showPreview(captured, scan);
                            },
                            onDelete: () {
                              final captured = ref.read(capturedImageProvider);
                              if (captured == null) return;
                              final path = captured.path;
                              final docs = ref.read(documentsProvider);
                              ref.read(documentsProvider.notifier).state =
                                  docs.where((p) => p != path).toList();
                              final kept = ref.read(keptScannedDocumentsProvider);
                              ref.read(keptScannedDocumentsProvider.notifier).state =
                                  kept.where((p) => p != path).toList();
                              ref.read(capturedImageProvider.notifier).state = null;
                              ref.read(cameraPathProvider.notifier).state = null;
                              ref.read(lastScanResultProvider.notifier).state = null;
                            },
                          ),
                        ),
                );
              },
            ),
          ),

          // Scanned documents stack
          Positioned(
            left: 24,
            bottom: 170,
            child: Consumer(
              builder: (context, ref, child) {
                final docs = ref.watch(documentsProvider);
                return AnimatedSwitcher(
                  duration: const Duration(milliseconds: 400),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  transitionBuilder: (child, animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(-0.2, 0),
                          end: Offset.zero,
                        ).animate(animation),
                        child: child,
                      ),
                    );
                  },
                  child: docs.isEmpty
                      ? const SizedBox.shrink(key: ValueKey('empty'))
                      : const ScannedDocumentsStack(key: ValueKey('stack')),
                );
              },
            ),
          ),

          // Document mode slider (A4, A3, Business Card, etc)
          Positioned(
            left: 0,
            right: 0,
            bottom: 110,
            child: const CameraModeSlider(),
          ),

          // Bottom action buttons
          CameraActionButtons(
            onCapture: _takePicture,
            onDiscard: () => Navigator.pop(context),
            onKeepScanning: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════
//  B&W Frame Overlay
// ══════════════════════════════════════════
class _BWFrameOverlay extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        painter: _BWCornerPainter(color: Colors.white.withValues(alpha: 0.5)),
      ),
    );
  }
}

class _BWCornerPainter extends CustomPainter {
  final Color color;
  _BWCornerPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    const len = 40.0;
    const margin = 24.0;

    // Top-left corner
    canvas.drawLine(
      const Offset(margin, margin),
      const Offset(margin + len, margin),
      paint,
    );
    canvas.drawLine(
      const Offset(margin, margin),
      const Offset(margin, margin + len),
      paint,
    );

    // Top-right corner
    canvas.drawLine(
      Offset(size.width - margin, margin),
      Offset(size.width - margin - len, margin),
      paint,
    );
    canvas.drawLine(
      Offset(size.width - margin, margin),
      Offset(size.width - margin, margin + len),
      paint,
    );

    // Bottom-left corner
    canvas.drawLine(
      Offset(margin, size.height - margin),
      Offset(margin + len, size.height - margin),
      paint,
    );
    canvas.drawLine(
      Offset(margin, size.height - margin),
      Offset(margin, size.height - margin - len),
      paint,
    );

    // Bottom-right corner
    canvas.drawLine(
      Offset(size.width - margin, size.height - margin),
      Offset(size.width - margin - len, size.height - margin),
      paint,
    );
    canvas.drawLine(
      Offset(size.width - margin, size.height - margin),
      Offset(size.width - margin, size.height - margin - len),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ══════════════════════════════════════════
//  B&W Captured Preview Bar
// ══════════════════════════════════════════
class _BWCapturedPreviewBar extends StatelessWidget {
  final XFile image;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _BWCapturedPreviewBar({
    required this.image,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(40),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(40),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.15),
              width: 0.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Thumbnail
          GestureDetector(
            onTap: onEdit,
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white,
                  width: 1.5,
                ),
                image: DecorationImage(
                  image: FileImage(File(image.path)),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _BWActionChip(
                  icon: Icons.tune_rounded,
                  label: 'Adjust',
                  color: Colors.white,
                  onPressed: onEdit,
                ),
                const SizedBox(width: 4),
                _BWActionChip(
                  icon: Icons.delete_outline_rounded,
                  label: '',
                  color: Colors.white54,
                  onPressed: onDelete,
                ),
              ],
            ),
          ),
        ],
      ),
      ),
      ),
    );
  }
}


class _BWActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onPressed;

  const _BWActionChip({
    required this.icon,
    required this.label,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(30),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 22),
            if (label.isNotEmpty) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.inter(
                  color: color,
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  letterSpacing: 0.5,
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }
}
