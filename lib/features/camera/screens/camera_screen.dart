import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:docsmind/constants/app_constants.dart';
import 'package:docsmind/core/providers.dart';
import 'package:docsmind/features/camera/providers/camera_providers.dart';
import 'package:docsmind/features/camera/widgets/camera_control_bar.dart';
import 'package:docsmind/features/camera/widgets/camera_preview_layer.dart';
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
    final f = ref.read(cameraControllerProvider).valueOrNull?.setFlashMode(mode);
    if (f != null) unawaited(f);
  }

  void _applyFocus(FocusMode mode) {
    final f = ref.read(cameraControllerProvider).valueOrNull?.setFocusMode(mode);
    if (f != null) unawaited(f);
  }

  Future<void> _initZoomRange(CameraController controller) async {
    try {
      final min = await controller.getMinZoomLevel();
      final max = await controller.getMaxZoomLevel();
      ref.read(cameraMinZoomProvider.notifier).state = min;
      ref.read(cameraMaxZoomProvider.notifier).state = max;
      final current = ref.read(cameraZoomLevelProvider);
      ref.read(cameraZoomLevelProvider.notifier).state = current.clamp(min, max);
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
    if (_frameCount % 10 != 0) return;
    final scanner = ref.read(documentScannerProvider);
    final detected = scanner.detectDocumentInCameraImage(image);
    if (!mounted) return;
    setState(() {
      if (detected) {
        _consecutiveDetections++;
      } else {
        _consecutiveDetections = 0;
      }
    });
    if (_consecutiveDetections >= 3) {
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

      final currentDocs = ref.read(documentsProvider);
      ref.read(documentsProvider.notifier).state = [...currentDocs, image.path];

      final scannerService = ref.read(documentScannerProvider);
      final scanResult = await scannerService.detectDocumentEdges(image.path);

      if (mounted) {
        await _showPreview(image, scanResult);
      }
    } catch (e) {
      ref.read(errorMessageProvider.notifier).state = 'Error taking picture: $e';
      debugPrint('Error taking picture: $e');
    } finally {
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
        onKeep: (corners) {
          final pathToSave = detectedDoc?.isDetected == true
              ? detectedDoc!.croppedPath
              : image.path;
          ref.read(cameraPathProvider.notifier).state = pathToSave;
          ref.read(capturedImageProvider.notifier).state = null;
          ref.read(errorMessageProvider.notifier).state = null;
          final kept = ref.read(keptScannedDocumentsProvider);
          ref.read(keptScannedDocumentsProvider.notifier).state = [...kept, pathToSave];
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
    ref.listen<FlashMode>(cameraFlashModeProvider, (_, next) => _applyFlash(next));
    ref.listen<FocusMode>(cameraFocusModeProvider, (_, next) => _applyFocus(next));
    ref.listen<double>(cameraZoomLevelProvider, (_, next) => _applyZoom(next));
    ref.listen<bool>(cameraAutoCaptureProvider, (prev, next) {
      if (next) {
        _maybeStartAutoCaptureStream(ref);
      } else {
        _stopStream();
      }
    });
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: const Text('Camera'),
        centerTitle: true,
        elevation: 0,
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          const CameraPreviewLayer(),
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: CameraControlBar(),
          ),
          Positioned(
            left: 16,
            bottom: 100,
            child: const ScannedDocumentsStack(),
          ),
          Positioned(
            right: 8,
            top: 120,
            bottom: 140,
            child: _ZoomSlider(onChanged: _applyZoom),
          ),
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

class _ZoomSlider extends ConsumerWidget {
  final ValueChanged<double> onChanged;

  const _ZoomSlider({required this.onChanged});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final min = ref.watch(cameraMinZoomProvider);
    final max = ref.watch(cameraMaxZoomProvider);
    final zoom = ref.watch(cameraZoomLevelProvider).clamp(min, max);
    return RotatedBox(
      quarterTurns: 3,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.black54,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.zoom_out, color: Colors.white, size: 18),
            Expanded(
              child: Slider(
                min: min,
                max: max,
                value: zoom,
                onChanged: (v) => onChanged(v),
                activeColor: Colors.white,
                inactiveColor: Colors.white24,
              ),
            ),
            const Icon(Icons.zoom_in, color: Colors.white, size: 18),
          ],
        ),
      ),
    );
  }
}
