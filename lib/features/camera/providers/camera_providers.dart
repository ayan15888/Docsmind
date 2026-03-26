import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:docsmind/features/camera/models/camera_filter.dart';

/// Async camera controller; auto-disposes when no longer used.
final cameraControllerProvider = AsyncNotifierProvider.autoDispose<
    CameraControllerNotifier, CameraController?>(CameraControllerNotifier.new);

class CameraControllerNotifier
    extends AutoDisposeAsyncNotifier<CameraController?> {
  CameraController? _controller;

  @override
  Future<CameraController?> build() async {
    // Register dispose synchronously before any await, so we never call
    // ref.onDispose after the provider was already disposed.
    ref.onDispose(() {
      _controller?.dispose();
      _controller = null;
    });

    final cameras = await availableCameras();
    CameraDescription rear;
    try {
      rear = cameras
          .firstWhere((c) => c.lensDirection == CameraLensDirection.back);
    } catch (_) {
      rear = cameras.first;
    }
    final controller = CameraController(
      rear,
      ResolutionPreset.max, // Full sensor resolution for document scanning
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );
    _controller = controller;
    await controller.initialize();
    return controller;
  }
}

/// Flash / torch mode for capture.
final cameraFlashModeProvider =
    StateProvider.autoDispose<FlashMode>((ref) => FlashMode.off);

/// Focus mode (auto vs locked).
final cameraFocusModeProvider =
    StateProvider.autoDispose<FocusMode>((ref) => FocusMode.auto);

/// Selected preview filter (visual overlay only).
final cameraFilterProvider =
    StateProvider.autoDispose<CameraFilterType>((ref) => CameraFilterType.none);

/// Last tap-to-focus point (null = use auto). Used when user taps on preview.
final cameraFocusPointProvider =
    StateProvider.autoDispose<Offset?>((ref) => null);

/// When true, camera auto-captures when a document is detected in the frame.
final cameraAutoCaptureProvider =
    StateProvider.autoDispose<bool>((ref) => false);

/// Current zoom level (1.0 = no zoom). Clamped to [cameraMinZoomProvider..cameraMaxZoomProvider].
final cameraZoomLevelProvider = StateProvider.autoDispose<double>((ref) => 1.0);

/// Device zoom range (populated after camera initialization).
final cameraMinZoomProvider = StateProvider.autoDispose<double>((ref) => 1.0);
final cameraMaxZoomProvider = StateProvider.autoDispose<double>((ref) => 8.0);

/// Live document presence flag while streaming camera frames.
final liveDocumentDetectedProvider =
    StateProvider.autoDispose<bool>((ref) => false);

/// Live document corners (normalized 0–1) used for the preview painter.
final liveDocumentCornersProvider =
    StateProvider.autoDispose<List<Offset>>((ref) => const []);

/// Document scanning mode (determines aspect ratio or template).
enum DocumentMode { auto, a4, a3, businessCard }

final cameraDocumentModeProvider =
    StateProvider.autoDispose<DocumentMode>((ref) => DocumentMode.auto);
